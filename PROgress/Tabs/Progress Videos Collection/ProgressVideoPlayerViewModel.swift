//
//  ProgressVideoPlayerViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import Foundation
import Observation
import Factory
import AVFoundation

@Observable @MainActor
class ProgressVideoPlayerViewModel {
    @ObservationIgnored
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    let videoAsset: VideoAsset
    
    var avAsset: AVURLAsset?
    
    init(videoAsset: VideoAsset) {
        self.videoAsset = videoAsset
        
        self.loadAVAsset()
    }
    
    func loadAVAsset() {
        Task.detached(priority: .userInitiated) {
            let avAsset = try await self.photoLibraryManager.getAVAsset(for: self.videoAsset.localIdentifier)
            
            await MainActor.run {
                self.avAsset = avAsset as? AVURLAsset
            }
        }
    }
}
