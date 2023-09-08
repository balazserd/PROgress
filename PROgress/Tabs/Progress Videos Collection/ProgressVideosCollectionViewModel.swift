//
//  ProgressVideosCollectionViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation
import Factory

@MainActor
class ProgressVideosCollectionViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager: PhotoLibraryManager
    
    @Published private(set) var videos: [VideoAsset]?
    @Published private(set) var videoLoadInProgress: Bool = false
    
    func loadProgressVideos() {
        self.videoLoadInProgress = true
        
        Task.detached {
            let videos = try await self.photoLibraryManager.getAllVideosOfPROgressMediaLibrary { _ in
                return
            } processing: { _ in
                return
            }
            
            await self.setVideos(to: videos)
        }
    }
    
    func setVideos(to videos: [VideoAsset]?) {
        self.videos = videos
        self.videoLoadInProgress = false
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
}
