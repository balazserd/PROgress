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
import Combine

@MainActor
class NewProgressVideoPlayerViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    @Injected(\.persistenceContainer) private var container
    
    @Published private(set) var saveStatus: SaveStatus?
    @Published var video: ProgressVideo
    
    
    init(video: ProgressVideo) {
        self.video = video
        
        self.setupSubscriptions()
    }
    
    func saveVideo() {
        self.setSaveVideoStatus(to: .inProgress)
        
        Task.detached {
            do {
                let persistentId = try await self.photoLibraryManager.saveProgressVideoToPhotoLibrary(self.video)
                
                await MainActor.run {
                    self.video.persistentIdentifier = persistentId
                }
                
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
    
    private var subscriptions = Set<AnyCancellable>()
    
    private func setupSubscriptions() {
        // If the video had already been saved, auto-save the new video name.
        $video
            .map { $0.name }
            .removeDuplicates()
            .sink { [weak self] newVideoName in
                guard let persistentIdentifier = self?.video.persistentIdentifier else {
                    PRLogger.app.notice("Cannot update persisted model!")
                    return
                }
                
                do {
                    try self?.container?.withNewContext {
                        guard let persistedVideo = $0.model(for: persistentIdentifier) as? ProgressVideo.Model else {
                            PRLogger.app.error("Did not find model in persistence store!")
                            return
                        }
                        
                        persistedVideo.name = newVideoName
                        try $0.save()
                        
                        PRLogger.app.debug("Updated model in persistence store!")
                        
                        NotificationCenter.default.post(name: .didUpdateProgressVideoProperties, object: nil)
                    }
                } catch let error {
                    PRLogger.app.error("Failed to update model in persistence store! [\(error)]")
                }
            }
            .store(in: &subscriptions)
    }
    
    enum SaveStatus {
        case inProgress
        case failed
        case finished
    }
}
