//
//  NewProgressVideoViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import Foundation
import SwiftUI
import PhotosUI
@preconcurrency import Combine
import EBUniAppsKit
import Factory
import ActivityKit

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    // MARK: - Injections
    @Injected(\.imageMergeEngine) private var imageMergeEngine
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    @Injected(\.activityManager) private var activityManager
    @Injected(\.persistenceContainer) private var container
    
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
    @Published var progressImages: [ProgressImage] = []
    
    @Published var isInFilteringMode: Bool = false
    @Published var imagesToExclude = Set<ProgressImage>()
    
    @Published var userSettings: VideoProcessingUserSettings!
    
    private var videoCreationLiveActivity: VideoCreationActivity?
    @Published private(set) var videoProcessingState: ImageMergeEngine.State = .idle
    @Published private(set) var video: ProgressVideo?
    @Published var videoName: String = "New progress video" {
        didSet {
            video?.name = videoName
        }
    }
    
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
        
        let assetIdentifiers = progressImages.compactMap { $0.localIdentifier }
        let isConvertingAlbum = selectedAlbum != nil
        
        Task.detached(priority: .userInitiated) { [photoUserOrdering, selectedItems] in
            var backgroundTaskId: UIBackgroundTaskIdentifier
            defer {
                Task { [backgroundTaskId] in
                    await UIApplication.shared.endBackgroundTask(backgroundTaskId)
                }
            }
            
            do {
                backgroundTaskId = await UIApplication.shared.beginBackgroundTask(withName: ImageMergeEngine.backgroundTaskName) { @Sendable in
                    Task {
                        let timeRemaining = await UIApplication.shared.backgroundTimeRemaining
                        PRLogger.app.info("Background task ended. Remaining time: \(timeRemaining) seconds.")
                    }
                }
                
                if backgroundTaskId == .invalid {
                    PRLogger.app.error("Background task could not be spawned!")
                }
                
                var thumbnails: VideoCreationActivityThumbnailData
                if isConvertingAlbum {
                    thumbnails = try await self.imageMergeEngine
                        .provideVideoCreationActivityThumbnails(from: assetIdentifiers,
                                                                by: .phAssetEngine(options: .detailed))
                } else {
                    thumbnails = try await self.imageMergeEngine
                        .provideVideoCreationActivityThumbnails(from: selectedItems,
                                                                by: .photosPickerItemEngine)
                }
                
                await self.setupLiveActivityForProgressVideo(with: thumbnails)
                
                let settings = await self.userSettings!
                let options = ImageMergeEngine.MergeOptions(customOrder: photoUserOrdering, userSettings: settings)
                
                PRLogger.app.info("The resulting video will be of size \(settings.extents.debugDescription).")
                
                var video: ProgressVideo
                if isConvertingAlbum {
                    // Order is automatically included here.
                    video = try await self.imageMergeEngine.mergeImages(assetIdentifiers,
                                                                        by: .phAssetEngine(options: .detailed),
                                                                        options: options)
                } else {
                    var images = selectedItems
                    if let order = options.customOrder {
                        images = order.map { images[$0] }
                    }
                    
                    video = try await self.imageMergeEngine.mergeImages(images,
                                                                        by: .photosPickerItemEngine,
                                                                        options: options)
                }
                
                video.name = await self.videoName // Do it manually once outside of didSet to pass default name.
                
                if await UIApplication.shared.applicationState == .background {
                    PRLogger.app.notice("App is in background, automatically saving video to Photo Library.")
                    let id = try await self.photoLibraryManager.saveProgressVideoToPhotoLibrary(video)
                    video.persistentIdentifier = id
                }
                
                await self.addVideoToView(video)
                
                if let activity = await self.videoCreationLiveActivity {
                    try await self.activityManager.endActivity(activity, with: .ended())
                }
            } catch let error {
                PRLogger.app.error("Video creation failed! \(error)")
                return
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
    
    func shouldExcludeProgressImage(_ progressImage: ProgressImage) -> Bool {
        self.imagesToExclude.contains(progressImage)
    }
    
    func toggleExclusionStatus(for progressImage: ProgressImage) {
        if shouldExcludeProgressImage(progressImage) {
            self.imagesToExclude.remove(progressImage)
        } else {
            self.imagesToExclude.insert(progressImage)
        }
    }
    
    func excludeMarkedProgressImages() {
        let indexesToRemove = self.imagesToExclude.compactMap {
            self.progressImages.firstIndex(of: $0)
        }
        
        self.progressImages.remove(atOffsets: .init(indexesToRemove))
        self.photoUserOrdering.remove(atOffsets: .init(indexesToRemove))
    }
    
    // MARK: - Private methods
    private func initializeBindings() {
        // Pop the view if a resolution was picked.
        $userSettings
            .compactMap { $0?.resolution }
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.navigationState.removeLast()
            }
            .store(in: &subscriptions)
        
        GlobalSettings.shared.$subscriptionType
            .map { $0 == .premium }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.userSettings?.hideLogo = isPremium
            }
            .store(in: &subscriptions)
        
        // Reset remove filter if filter mode has been toggled off.
        $isInFilteringMode
            .dropFirst() // Drop initial value
            .removeDuplicates()
            .filter { !$0 }
            .sink { [weak self] _ in
                self?.imagesToExclude.removeAll()
            }
            .store(in: &subscriptions)
    }
    
    private func setInitialUserSettings() {
        let largestPhotoSize = progressImages.reduce(CGSize.zero) {
            CGSize(width: max($0.width, $1.originalSize.width),
                   height: max($0.height, $1.originalSize.height))
        }
        
        self.userSettings = VideoProcessingUserSettings(maxPhotoExtentX: largestPhotoSize.width,
                                                        maxPhotoExtentY: largestPhotoSize.height)
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
            await setInitialUserSettings()
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
            await setInitialUserSettings()
            await updateState(to: .success)
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private func setupLiveActivityForProgressVideo(with thumbnails: VideoCreationActivityThumbnailData) async {
        let attributes = VideoCreationLiveActivityAttributes(firstImage: thumbnails.firstImageData,
                                                             middleImages: thumbnails.middleImagesData,
                                                             lastImage: thumbnails.lastImageData)
        let activity = await MainActor.run { [attributes] in
            self.videoCreationLiveActivity = .videoCreation(attributes)
            return self.videoCreationLiveActivity!
        }
        
        do {
            try await self.activityManager.startActivity(activity)
        } catch let error {
            PRLogger.activities.error("Activity couldn't be started: \(error)")
        }
        
        // Update live activity when image merging progresses
        Task.detached { [weak self] in
            guard let self = self else { return }
            
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
    
    private func setProgressImages(to images: [ProgressImage]) {
        self.progressImages = images
    }
    
    private func updateState(to state: ImageLoadingState) {
        if case .success = state, self.progressImages.isEmpty {
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

extension NewProgressVideoViewModel {
    static var previewForLoadedImagesView: NewProgressVideoViewModel = {
        let vm = NewProgressVideoViewModel()
        vm.userSettings = VideoProcessingUserSettings()
        vm.progressImages = []
        
        return vm
    }()
    
    static var previewForVideoSettings: NewProgressVideoViewModel = {
        let vm = NewProgressVideoViewModel()
        vm.userSettings = VideoProcessingUserSettings()
        
        return vm
    }()
}
