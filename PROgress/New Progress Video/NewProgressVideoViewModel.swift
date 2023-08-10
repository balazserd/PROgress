//
//  NewProgressVideoViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import Foundation
import SwiftUI
import PhotosUI
import EBUniAppsKit
import Factory

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    @Injected(\.imageMergeEngine) private var imageMergeEngine
    
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            Task.detached { await self.loadImages(from: self.selectedItems) }
        }
    }
    
    @Published private(set) var imageLoadingState: ImageLoadingState = .undefined
    @Published private(set) var videoProcessingState: ImageMergeEngine.State = .idle
    @Published private(set) var video: ProgressVideo?
    
    func beginMerge() {
        guard case .success = self.imageLoadingState else {
            PRLogger.app.fault("beginMerge() was called without a success state!")
            return
        }
        
        Task.detached(priority: .userInitiated) { [selectedItems] in
            do {
                _ = try await self.imageMergeEngine.mergeImages(selectedItems)
            } catch let error {
                PRLogger.app.error("Video creation failed! \(error)")
                return
            }
            
            if case let .finished(video) = await self.videoProcessingState {
                await self.addVideoToView(video)
            }
        }
        
        imageMergeEngine.state
            .receive(on: DispatchQueue.main)
            .assign(to: &$videoProcessingState)
    }
    
    func clearVideoProcessingState() {
        self.videoProcessingState = .idle
    }
    
    private nonisolated func loadImages(from selection: [PhotosPickerItem]) async {
        guard await selectedItems.count > 0 else { return }
        
        await updateState(to: .loading(progress: 0.0))
        
        typealias IndexedImage = (image: ProgressImage?, index: Int)
        do {
            let taskLimit = ProcessInfo.recommendedMaximumConcurrency
            let progressImages = try await selection.mapAsync(maxConcurrencyCount: taskLimit) { [weak self] in
                let transferable = try await $0.loadTransferable(type: ProgressImage.self)
                await self?.advanceLoadingProgress(by: 1.0 / Double(selection.count))
                return IndexedImage(transferable, selection.firstIndex(of: $0) ?? .max)
            }
            .sorted(by: { $0.index < $1.index })
            .map { $0.image }
            .compactMap { $0 }
            
            PRLogger.app.debug("Successfully imported \(progressImages.count) photos")
            await updateState(to: .success(images: progressImages))
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private func updateState(to state: ImageLoadingState) {
        self.imageLoadingState = state
    }
    
    private func advanceLoadingProgress(by value: Double) {
        guard case let .loading(currentProgress) = self.imageLoadingState else {
            PRLogger.app.warning("Cannot advance loading progress without `.loading` being the current state!")
            return
        }
        
        self.imageLoadingState = .loading(progress: min(1.0, currentProgress + value))
    }
    
    private func addVideoToView(_ video: ProgressVideo) {
        self.video = video
    }
    
    enum ImageLoadingState {
        case undefined
        case loading(progress: Double)
        case success(images: [ProgressImage])
        case failure(Error)
    }
}
