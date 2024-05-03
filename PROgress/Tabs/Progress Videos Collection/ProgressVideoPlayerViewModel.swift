//
//  ProgressVideoPlayerViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import Foundation
import Observation
import Factory
@preconcurrency import AVFoundation
import os

@Observable @MainActor
class ProgressVideoPlayerViewModel {
    @ObservationIgnored
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    let videoAsset: VideoAsset
    
    var avAsset: AVURLAsset?
    var assetAspectRatio: CGSize?
    
    init(videoAsset: VideoAsset) {
        self.videoAsset = videoAsset
        
        self.loadAVAsset()
    }
    
    func loadAVAsset() {
        Task.detached(priority: .userInitiated) {
            let avAsset = try await self.photoLibraryManager.getAVAsset(for: self.videoAsset.localIdentifier)
            let assetSize = try await self.aspectRatio(for: avAsset)
            
            await MainActor.run {
                self.avAsset = avAsset as? AVURLAsset
                self.assetAspectRatio = assetSize
            }
        }
    }
    
    nonisolated private func aspectRatio(for asset: AVAsset) async throws -> CGSize? {
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            PRLogger.app.error("Asset has no video track!")
            return nil
        }
        
        let (size, preferredTransform) = try await track.load(.naturalSize, .preferredTransform)
        return size.applying(preferredTransform)
    }
}
