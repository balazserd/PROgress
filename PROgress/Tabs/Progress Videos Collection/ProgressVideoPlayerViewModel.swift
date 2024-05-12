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
import SwiftData
import SwiftUI

@Observable @MainActor
class ProgressVideoPlayerViewModel {
    @ObservationIgnored
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    @ObservationIgnored
    @Injected(\.persistenceContainer) private var container
    
    var videoAsset: VideoAsset {
        willSet {
            if videoAsset.name != newValue.name, let newName = newValue.name {
                self.updatePersistedVideoAssetName(to: newName)
            }
        }
    }
    
    var videoAssetNameBinding: Binding<String> {
        Binding<String>(get: { self.videoAsset.name ?? "" },
                        set: { self.videoAsset.name = $0 })
    }
    
    var avAsset: AVURLAsset? {
        didSet {
            guard avAsset != nil else { return }
            player = AVPlayer(url: avAsset!.url)
        }
    }
    
    var player: AVPlayer?
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
    
    private func updatePersistedVideoAssetName(to newName: String) {
        Task.detached { [localIdentifier = self.videoAsset.localIdentifier] in
            do {
                try await self.container?.withNewContext {
                    let fetchDescriptor = FetchDescriptor(predicate: .matchingLocalIdentifier(localIdentifier))
                    guard let persistedVideoAsset = try $0.fetch(fetchDescriptor).first else {
                        PRLogger.persistence.error("Persisted video asset not found!")
                        return
                    }
                    
                    persistedVideoAsset.name = newName
                    
                    try $0.save()
                }
                
                NotificationCenter.default.post(name: .didUpdateProgressVideoProperties, object: nil)
            } catch let error {
                PRLogger.persistence.error("Failed to update video name! \(error)")
            }
        }
    }
}
