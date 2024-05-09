//
//  ProgressVideosCollectionViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation
import Factory
import SwiftData
import Combine
import os
import SwiftUI

@MainActor
class ProgressVideosCollectionViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager: PhotoLibraryManager
    @Injected(\.persistenceContainer) private var container
               
    @Published private(set) var searchCriteriaFulfillingVideos: [VideoAsset] = []
    @Published private(set) var videos: [VideoAsset]?
    @Published private(set) var videoLoadInProgress: Bool = false
    @Published private(set) var error: VideoRetrievalError?
    
    @Published var isEditing = false
    @Published var videosToDelete = Set<VideoAsset>()
    @Published var searchText: String = ""
    @Published var navigationState = NavigationPath()
    
    init() { 
        setupBindings()
        loadProgressVideos()
    }
    
    func loadProgressVideos() {
        PRLogger.app.debug("Initiating refresh of progress video list.")
        
        self.videoLoadInProgress = true
        
        guard container != nil else {
            PRLogger.persistence.error("Container creation failed!")
            self.error = .containerCreationFailure
            
            return
        }
        
        Task {
            let getVideosFromAlbumTask = Task.detached {
                return try await self.photoLibraryManager.getAllVideosOfPROgressMediaLibrary()
            }
            
            do {
                let persistedVideos = try container!.mainContext.fetch(ProgressVideo.Model.descriptorForAllItems())
                var videoAssetsInAlbum = try await getVideosFromAlbumTask.value
                
                videoAssetsInAlbum.addAssetNamesFromPersistentStore(persistedAssets: persistedVideos)
                
                self.videos = videoAssetsInAlbum
            } catch let error {
                PRLogger.persistence.error("Could not fetch videos from backing store! [\(error)]")
                self.error = .fetchRequestError
            }
            
            self.videoLoadInProgress = false
            self.isEditing = false
        }
    }
    
    func deleteMarkedVideos() {
        Task {
            do {
                try await photoLibraryManager.deleteVideoAssetsFromPROgressLibrary(assets: Array(videosToDelete))
            } catch let error {
                PRLogger.persistence.error("Could not remove videos! [\(error)]")
            }
            
            videosToDelete.removeAll()
        }
    }
    
    func shouldRemoveVideo(_ video: VideoAsset) -> Bool {
        self.videosToDelete.contains(video)
    }
    
    func toggleDeletionStatus(for video: VideoAsset) {
        if shouldRemoveVideo(video) {
            self.videosToDelete.remove(video)
        } else {
            self.videosToDelete.insert(video)
        }
    }
    
    lazy var videoDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }()
    
    lazy var videoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        
        return formatter
    }()
    
    // MARK: - Private functions
    private var subscriptions = Set<AnyCancellable>()
    private func setupBindings() {
        Publishers.CombineLatest($videos, $searchText)
            .compactMap { (videos, searchText) in
                if searchText.isEmpty {
                    return videos
                }
                
                return videos?.filter { $0.name?.contains(searchText) == true }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &self.$searchCriteriaFulfillingVideos)
        
        Publishers.Merge(NotificationCenter.default.publisher(for: .didCreateNewProgressVideo),
                         NotificationCenter.default.publisher(for: .didRemoveProgressVideos))
            .sink { [weak self] _ in
                self?.loadProgressVideos()
            }
            .store(in: &subscriptions)
    }
    
    enum VideoRetrievalError: Error {
        case containerCreationFailure
        case fetchRequestError
    }
}
