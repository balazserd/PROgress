//
//  NewProgressVideoPlayerViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import Factory
import SwiftUI
import SwiftData

@MainActor
class NewProgressVideoPlayerViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    @Injected(\.persistenceContainer) private var container
    
    @Published private(set) var saveStatus: SaveStatus?
    @Published private(set) var video: ProgressVideo
    
    init(video: ProgressVideo) {
        self.video = video
    }
    
    func saveVideo() {
        self.setSaveVideoStatus(to: .inProgress)
        
        Task.detached {
            do {
                try await self.photoLibraryManager.saveProgressVideoToPhotoLibrary(self.video)
                
                await self.setSaveVideoStatus(to: .finished)
            } catch let error {
                PRLogger.app.error("Failed to save video! [\(error)]")
                await self.setSaveVideoStatus(to: .failed)
            }
        }
    }
    
    func setSaveVideoStatus(to status: SaveStatus) {
        if status == .finished {
            self.video.persisted = true
        }
        
        withAnimation(.easeInOut) {
            self.saveStatus = status
        }
    }
    
    enum SaveStatus {
        case inProgress
        case failed
        case finished
    }
}
