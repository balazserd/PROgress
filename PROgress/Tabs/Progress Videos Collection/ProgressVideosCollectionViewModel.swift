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

@MainActor
class ProgressVideosCollectionViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager: PhotoLibraryManager
    @Injected(\.persistenceContainer) private var container
               
    @Published private(set) var searchCriteriaFulfillingVideos: [VideoAsset] = []
    @Published private(set) var videos: [VideoAsset]?
    @Published private(set) var videoLoadInProgress: Bool = false
    @Published private(set) var error: VideoRetrievalError?
    
    @Published var searchText: String = ""
    
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
                let persistedVideos = try container!.mainContext.fetch(ProgressVideo.Model.allItemsDescriptor())
                var videoAssetsInAlbum = try await getVideosFromAlbumTask.value
                
                VideoAsset.addAssetNamesFromPersistentStore(assets: &videoAssetsInAlbum,
                                                            persistedAssets: persistedVideos)
                
                self.videos = videoAssetsInAlbum
            } catch let error {
                PRLogger.persistence.error("Could not fetch videos from backing store! [\(error)]")
                self.error = .fetchRequestError
            }
            
            self.videoLoadInProgress = false
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
        
        NotificationCenter.default.publisher(for: .didCreateNewProgressVideo)
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
