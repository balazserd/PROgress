//
//  NewProgressVideoViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import Foundation
import SwiftUI
import PhotosUI
import Combine
import EBUniAppsKit
import Factory
import ActivityKit

struct VideoProcessingUserSettings {
    var timeBetweenFrames: Double
    var resolution: Resolution {
        didSet {
            guard oldValue != resolution else { return }
            
            switch resolution {
            case .customWidthPreservedAspectRatio:
                customExtentAxis = .horizontal
                aspectRatio = Double(extentX) / Double(extentY)
                
            case .custom:
                customExtentAxis = nil
                aspectRatio = nil
                
            default: break
            }
        }
    }
    var extentX: Double {
        didSet {
            guard customExtentAxis == .horizontal else { return }
            extentY = extentX / aspectRatio
        }
    }
    
    var extentY: Double {
        didSet {
            guard customExtentAxis == .vertical else { return }
            extentX = extentY * aspectRatio
        }
    }
    
    var customExtentAxis: Axis?
    
    private(set) var aspectRatio: Double!
    
    init(timeBetweenFrames: Double = 0.2,
         resolution: Resolution = .customWidthPreservedAspectRatio,
         extentX: Double = 640,
         extentY: Double = 320,
         customExtentAxis: Axis? = .horizontal) {
        self.timeBetweenFrames = timeBetweenFrames
        self.resolution = resolution
        self.extentX = extentX
        self.extentY = extentY
        
        self.customExtentAxis = customExtentAxis
        if customExtentAxis != nil {
            aspectRatio = extentX / extentY
        }
    }
    
    enum Resolution: String, CaseIterable {
        case tiny = "Tiny"
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case ultra = "Ultra"
        case customWidthPreservedAspectRatio = "Custom (preserve aspect ratio)"
        case custom = "Custom (both extents)"
        
        var displayName: String { self.rawValue }
        
        var shortName: String {
            switch self {
            case .custom: return "Custom (free)"
            case .customWidthPreservedAspectRatio: return "Custom (aspect fixed)"
            default: return self.displayName
            }
        }
        
        var maxExtentLength: Int? {
            switch self {
            case .tiny: return 480
            case .low: return 640
            case .medium: return 800
            case .high: return 1280
            case .ultra: return 1920
            default: return nil
            }
        }
        
        var isFree: Bool {
            switch self {
            case .tiny, .low, .medium: return true
            default: return false
            }
        }
    }
}

extension Axis {
    var displayName: String {
        switch self {
        case .horizontal: return "Width"
        case .vertical: return "Height"
        }
    }
}

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    // MARK: - Injections
    @Injected(\.imageMergeEngine) private var imageMergeEngine
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    @Injected(\.activityManager) private var activityManager
    
    // MARK: - Variables
    @Published var navigationState = NavigationPath()
    
    /// This item tracks any ordering changes that is done by the user over the photos.
    ///
    /// ``selectedItems`` cannot directly track this, as it's a published variable.
    @Published var photoUserOrdering: [Int] = []
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            self.selectedAlbum = nil
            self.photoUserOrdering = Array(0..<selectedItems.count)
            
            Task.detached { [selectedItems] in
                await self.loadImages(from: selectedItems)
            }
        }
    }
    
    @Published private(set) var imageLoadingState: ImageLoadingState = .undefined
    @Published var progressImages: [ProgressImage]?
    
    @Published var userSettings = VideoProcessingUserSettings()
    
    private var videoCreationLiveActivity: VideoCreationActivity?
    @Published private(set) var videoProcessingState: ImageMergeEngine.State = .idle
    @Published private(set) var video: ProgressVideo?
    
    @Published private(set) var photoAlbumsLoadingState: PhotoAlbumsLoadingState = .undefined
    @Published private(set) var photoAlbums: [PhotoAlbum]?
    @Published var selectedAlbum: PhotoAlbum? {
        didSet {
            guard selectedAlbum != nil else { return }
            self.photoUserOrdering = Array(0..<selectedAlbum!.imageCount)
            
            Task.detached {
                await self.loadImages(for: self.selectedAlbum!)
            }
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        initializeBindings()
    }
    
    // MARK: - Public methods
    func beginMerge() {
        guard case .success = self.imageLoadingState else {
            PRLogger.app.fault("beginMerge() was called without a success state!")
            return
        }
        
        let largestPhotoSize = progressImages!.reduce(CGSize.zero) {
            CGSize(width: max($0.width, $1.originalSize.width),
                   height: max($0.height, $1.originalSize.height))
        }
        let assetIdentifiers = progressImages!.compactMap { $0.localIdentifier }
        let isConvertingAlbum = selectedAlbum != nil
        
        Task.detached(priority: .userInitiated) { [photoUserOrdering, selectedItems] in
            var backgroundTaskId: UIBackgroundTaskIdentifier
            defer {
                Task { [backgroundTaskId] in
                    await UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
            }
            
            do {
                backgroundTaskId = await UIApplication.shared.beginBackgroundTask(withName: ImageMergeEngine.backgroundTaskName) { @Sendable () -> () in
                    Task {
                        let timeRemaining = await UIApplication.shared.backgroundTimeRemaining
                        PRLogger.app.notice("Background task ended. Remaining time: \(timeRemaining) seconds.")
                    }
                }
                
                if backgroundTaskId == .invalid {
                    PRLogger.app.error("Background task could not be spawned!")
                }
                
                var thumbnails: VideoCreationActivityThumbnailData
                if isConvertingAlbum {
                    thumbnails = try await self.imageMergeEngine.provideVideoCreationActivityThumbnails(from: assetIdentifiers,
                                                                                                        by: .phAssetEngine(options: .detailed))
                } else {
                    thumbnails = try await self.imageMergeEngine.provideVideoCreationActivityThumbnails(from: selectedItems,
                                                                                                        by: .photosPickerItemEngine)
                }
                
                let attributes = VideoCreationLiveActivityAttributes(firstImage: thumbnails.firstImageData,
                                                                     middleImages: thumbnails.middleImagesData,
                                                                     lastImage: thumbnails.lastImageData)
                let activity = await MainActor.run { [attributes] in
                    self.videoCreationLiveActivity = .videoCreation(attributes)
                    return self.videoCreationLiveActivity!
                }
                
                try await self.activityManager.startActivity(activity)
                
                let options = ImageMergeEngine.MergeOptions(size: largestPhotoSize,
                                                            customOrder: photoUserOrdering)
                
                PRLogger.app.info("The resulting video will be of size \(largestPhotoSize.debugDescription).")
                
                var video: ProgressVideo
                if isConvertingAlbum {
                    video = try await self.imageMergeEngine.mergeImages(assetIdentifiers,
                                                                        by: .phAssetEngine(options: .detailed),
                                                                        options: options)
                } else {
                    video = try await self.imageMergeEngine.mergeImages(selectedItems,
                                                                        by: .photosPickerItemEngine,
                                                                        options: options)
                }
                
                await self.addVideoToView(video)
                
                if await UIApplication.shared.applicationState == .background {
                    PRLogger.app.notice("App is in background, automatically saving video to Photo Library.")
                    try await self.photoLibraryManager.saveAssetToPhotoLibrary(assetAtUrl: video.url)
                }
                
                try await self.activityManager.endActivity(activity, with: .ended())
            } catch let error {
                PRLogger.app.error("Video creation failed! \(error)")
                return
            }
        }
        
        Task.detached { [unowned self] in
            for await state in await self.imageMergeEngine.state.values {
                await MainActor.run {
                    self.videoProcessingState = state
                }
                
                if  case .working(let progress) = state,
                    let activity = await self.videoCreationLiveActivity
                {
                    do {
                        try await self.activityManager.updateActivity(activity, with: .inProgress(value: progress))
                    } catch let error {
                        PRLogger.app.error("Failed to update live activity! [\(error)]")
                    }
                }
            }
        }
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
    private func initializeBindings() {
        // Pop the view if a resolution was picked.
        $userSettings
            .map { $0.resolution }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.navigationState.removeLast()
            }
            .store(in: &subscriptions)
    }
    
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
            let progressImages = try await photoLibraryManager.getAllPhotosOfAlbum(album, to: .display) {
                Task { @MainActor [weak self] in
                    self?.advanceLoadingProgress(by: 1.0 / Double(album.imageCount))
                }
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
