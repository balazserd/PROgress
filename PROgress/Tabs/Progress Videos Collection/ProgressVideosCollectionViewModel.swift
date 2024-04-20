//
//  ProgressVideosCollectionViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation
import Factory
import SwiftData
import os

@MainActor
class ProgressVideosCollectionViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager: PhotoLibraryManager
    @Injected(\.persistenceContainer) private var container
               
    @Published private(set) var videos: [VideoAsset]?
    @Published private(set) var videoLoadInProgress: Bool = false
    @Published private(set) var error: VideoRetrievalError?
    
    func loadProgressVideos() {
        self.videoLoadInProgress = true
        
        guard container != nil else {
            PRLogger.persistence.error("Container creation failed!")
            self.error = .containerCreationFailure
            
            return
        }
        
        Task {
            var getVideosFromAlbumTask = Task.detached {
                let videos = try await self.photoLibraryManager.getAllVideosOfPROgressMediaLibrary { _ in
                    return
                } processing: { _ in
                    return
                }
                
                return videos
            }
            
            do {
                var persistedVideos = try container!.mainContext.fetch(ProgressVideo.Model.allItemsDescriptor())
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
    
    enum VideoRetrievalError: Error {
        case containerCreationFailure
        case fetchRequestError
    }
}
