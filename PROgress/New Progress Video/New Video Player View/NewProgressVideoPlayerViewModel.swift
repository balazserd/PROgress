//
//  NewProgressVideoPlayerViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import Factory

@MainActor
class NewProgressVideoPlayerViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    @Published private(set) var saveStatus: SaveStatus?
    
    func saveVideo(_ progressVideo: ProgressVideo) {
        self.setSaveVideoStatus(to: .inProgress)
        
        Task.detached {
            do {
                try await self.photoLibraryManager.saveAssetToPhotoLibrary(atUrl: progressVideo.url)
                
                await self.setSaveVideoStatus(to: .finished)
            } catch let error {
                PRLogger.app.error("Failed to save video! [\(error)]")
                await self.setSaveVideoStatus(to: .failed)
            }
        }
    }
    
    func setSaveVideoStatus(to status: SaveStatus) {
        self.saveStatus = status
    }
    
    enum SaveStatus {
        case inProgress
        case failed
        case finished
    }
}
