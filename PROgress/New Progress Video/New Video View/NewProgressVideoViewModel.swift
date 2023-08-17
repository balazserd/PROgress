//
//  NewProgressVideoViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import Foundation
import SwiftUI
import PhotosUI
import EBUniAppsKit
import Factory

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    // MARK: - Injections
    @Injected(\.imageMergeEngine) private var imageMergeEngine
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    // MARK: - Public variables
    @Published var navigationState = NavigationPath()
    
    /// This item tracks any ordering changes that is done by the user over the photos.
    ///
    /// ``selectedItems`` cannot directly track this, as it's a published variable.
    @Published var orderedSelectedItems: [PhotosPickerItem] = []
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            self.orderedSelectedItems = selectedItems
            
            Task.detached { await self.loadImages(from: self.selectedItems) }
        }
    }
    
    @Published private(set) var imageLoadingState: ImageLoadingState = .undefined
    @Published var progressImages: [ProgressImage]?
    
    @Published private(set) var videoProcessingState: ImageMergeEngine.State = .idle
    @Published private(set) var video: ProgressVideo?
    
    @Published private(set) var photoAlbumsLoadingState: PhotoAlbumsLoadingState = .undefined
    @Published private(set) var photoAlbums: [PhotoAlbum]?
    @Published var selectedAlbum: PhotoAlbum? {
        didSet {
            guard selectedAlbum != nil else { return }
            
            Task.detached {
                await self.loadImages(for: self.selectedAlbum!)
                
                let orderedPhotosPickerItems = await self.progressImages?.map {
                    PhotosPickerItem(itemIdentifier: $0.localIdentifier)
                } ?? []
                
                await self.setOrderedSelectedItems(to: orderedPhotosPickerItems)
            }
        }
    }

    // MARK: - Public methods
    func beginMerge() {
        guard case .success = self.imageLoadingState else {
            PRLogger.app.fault("beginMerge() was called without a success state!")
            return
        }
        
        Task.detached(priority: .userInitiated) { [progressImages, orderedSelectedItems] in
            do {
                let largestPhotoSize = progressImages!.reduce(CGSize.zero) {
                        CGSize(width: max($0.width, $1.originalSize.width),
                               height: max($0.height, $1.originalSize.height))
                    }
                
                PRLogger.app.info("The resulting video will be of size \(largestPhotoSize.debugDescription).")
                
                let video = try await self.imageMergeEngine.mergeImages(orderedSelectedItems,
                                                                        options: .init(size: largestPhotoSize))
                await self.addVideoToView(video)
            } catch let error {
                PRLogger.app.error("Video creation failed! \(error)")
                return
            }
        }
        
        imageMergeEngine.state
            .receive(on: DispatchQueue.main)
            .assign(to: &$videoProcessingState)
    }
    
    func resetVideoProcessingState() {
        self.videoProcessingState = .idle
    }
    
    func watchVideo() {
        resetVideoProcessingState()
        
        if let video = video {
            self.navigationState.append(video)
        }
    }
    
    func loadPhotoAlbums() {
        self.setPhotoAlbumsLoadingState(to: .loading)
        
        Task.detached { [photoLibraryManager] in
            do {
                let albumCollection = try await photoLibraryManager.getPhotoAlbumCollection()
                let albums = await albumCollection.photoAlbums
                await self.setPhotoAlbumsLoadingState(to: .success(albums: albums))
            } catch let error {
                PRLogger.app.error("Could not get albumCollection! [\(error)]")
                await self.setPhotoAlbumsLoadingState(to: .failure)
            }
        }
    }
    
    // MARK: - Private methods
    private nonisolated func loadImages(from selection: [PhotosPickerItem]) async {
        guard await selectedItems.count > 0 else { return }
        
        await updateState(to: .loading(progress: 0.0))
        
        typealias IndexedImage = (image: ProgressImage?, index: Int)
        do {
            let taskLimit = ProcessInfo.recommendedMaximumConcurrency
            let progressImages = try await selection.mapAsync(maxConcurrencyCount: taskLimit) { [weak self] in
                var transferable = try await $0.loadTransferable(type: ProgressImage.self)
                transferable?.localIdentifier = $0.itemIdentifier
                
                await self?.advanceLoadingProgress(by: 1.0 / Double(selection.count))
                return IndexedImage(transferable, selection.firstIndex(of: $0) ?? .max)
            }
            .sorted(by: { $0.index < $1.index })
            .map { $0.image }
            .compactMap { $0 }
            
            PRLogger.app.debug("Successfully imported \(progressImages.count) photos")
            await setProgressImages(to: progressImages)
            await updateState(to: .success)
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private nonisolated func loadImages(for album: PhotoAlbum) async {
        await updateState(to: .loading(progress: 0.0))
        
        do {
            let progressImages = try await photoLibraryManager.getAllPhotosOfAlbum(album, to: .display) { [weak self] in
                await self?.advanceLoadingProgress(by: 1.0 / Double(album.imageCount))
            }
            
            PRLogger.app.debug("Successfully imported \(album.imageCount) photos")
            await setProgressImages(to: progressImages)
            await updateState(to: .success)
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private func setProgressImages(to images: [ProgressImage]) {
        self.progressImages = images
    }
    
    private func updateState(to state: ImageLoadingState) {
        if case .success = state, self.progressImages == nil {
            PRLogger.app.fault("Settings success state without `progressImages` being set!")
        }
        
        self.imageLoadingState = state
    }
    
    private func advanceLoadingProgress(by value: Double) {
        guard case let .loading(currentProgress) = self.imageLoadingState else {
            PRLogger.app.warning("Cannot advance loading progress without `.loading` being the current state!")
            return
        }
        
        self.imageLoadingState = .loading(progress: min(1.0, currentProgress + value))
    }
    
    private func setOrderedSelectedItems(to items: [PhotosPickerItem]) {
        self.orderedSelectedItems = items
    }
    
    private func addVideoToView(_ video: ProgressVideo) {
        self.video = video
    }
    
    private func setPhotoAlbumsLoadingState(to state: PhotoAlbumsLoadingState) {
        self.photoAlbumsLoadingState = state
    }
    
    // MARK: - ImageLoadingState enum
    enum ImageLoadingState {
        case undefined
        case loading(progress: Double)
        case success
        case failure(Error)
        
        var isSuccess: Bool {
            guard case .success = self else { return false }
            return true
        }
    }
    
    enum PhotoAlbumsLoadingState {
        case undefined
        case loading
        case success(albums: [PhotoAlbum])
        case failure
    }
}
