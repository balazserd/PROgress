//
//  NewProgressVideoPlayerViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import Factory
import SwiftUI

@MainActor
class NewProgressVideoPlayerViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    @Published private(set) var saveStatus: SaveStatus?
    
    func saveVideo(_ progressVideo: ProgressVideo) {
        self.setSaveVideoStatus(to: .inProgress)
        
        Task.detached {
            do {
                try await self.photoLibraryManager.saveAssetToPhotoLibrary(assetAtUrl: progressVideo.url)
                
                await self.setSaveVideoStatus(to: .finished)
            } catch let error {
                PRLogger.app.error("Failed to save video! [\(error)]")
                await self.setSaveVideoStatus(to: .failed)
            }
        }
    }
    
    func setSaveVideoStatus(to status: SaveStatus) {
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
