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

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            Task.detached { await self.loadImages(from: self.selectedItems) }
        }
    }
    
    @Published private(set) var state: ImageLoadingState = .undefined
    @Published private(set) var loadingProgress: Double = 0.0
    
    private nonisolated func loadImages(from selection: [PhotosPickerItem]) async {
        guard await selectedItems.count > 0 else { return }
        
        await updateState(to: .loading)
        
        typealias IndexedImage = (image: ProgressImage?, index: Int)
        do {
            let progressImageIndexedArray = try await withThrowingTaskGroup(of: IndexedImage.self) { group in
                let taskLimit = max(ProcessInfo().activeProcessorCount - 2, 1)
                
                return try await selection.mapAsync(in: &group, maxConcurrencyCount: taskLimit) { [weak self] in
                    let transferable = try await $0.loadTransferable(type: ProgressImage.self)
                    await self?.advanceLoadingProgress(by: 1.0 / Double(selection.count))
                    return (transferable, selection.firstIndex(of: $0) ?? .max)
                }
            }
            
            let progressImageArray = progressImageIndexedArray
                .sorted(by: { $0.index < $1.index })
                .map { $0.image }
                .compactMap { $0 }
            
            PRLogger.app.debug("Successfully imported \(progressImageArray.count) photos")
            await updateState(to: .success(progressImageArray))
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private func updateState(to state: ImageLoadingState) {
        self.state = state
    }
    
    private func advanceLoadingProgress(by value: Double) {
        self.loadingProgress = min(1.0, self.loadingProgress + value)
    }
    
    enum ImageLoadingState {
        case undefined
        case loading
        case success([ProgressImage])
        case failure(Error)
    }
}
