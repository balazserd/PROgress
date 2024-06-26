//
//  PhotoLibraryManager.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import Photos
import SwiftUI
import UIKit
import AVFoundation
import Factory
import SwiftData

actor PhotoLibraryManager {
    @Injected(\.persistenceContainer) private var container
    @Injected(\.imageMergeEngine) private var imageMergeEngine
    
    var authorizationStatus: PHAuthorizationStatus
    
    static let videoLibraryTitle = "PROgress"
    
    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - Working with albums
    /// The PROgress app's designated video folder.
    nonisolated func getPROgressMediaLibraryAssetCollection() -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title LIKE %@", Self.videoLibraryTitle)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            
        if assetCollections.count > 1 {
            PRLogger.photoLibraryManagement.fault("Unexpectedly found more than 1 matching libraries!")
        }
        
        if let library = assetCollections.firstObject {
            return library
        } else {
            PRLogger.photoLibraryManagement.notice("Did not find the designated video library!")
            return nil
        }
    }
    
    /// Returns all videos in the PROgress app's designated video folder.
    func getAllVideosOfPROgressMediaLibrary(
        retrieval assetRetrievalProgressBlock: @escaping @Sendable (Double) -> Void = { _ in return },
        processing assetProcessingProgressBlock: @escaping @Sendable (Double) -> Void = { _ in return }
    ) async throws -> [VideoAsset] {
        try await handleAuthorizationStatus()
        
        guard let videoLibrary = self.getPROgressMediaLibraryAssetCollection() else {
            PRLogger.photoLibraryManagement.fault("Video library should exist!")
            throw OperationError.videoLibraryNotFound
        }
        
        typealias VideoAssetSource = (
            imageGenerator: AVAssetImageGenerator,
            length: Double,
            name: String
        )
        
        let rawVideoAssets = PHAsset.fetchAssets(in: videoLibrary, options: .videosInAlbum)
        let progressUnit = 1.0 / Double(rawVideoAssets.count)
        
        let videoAssetSourcesTask = Task.detached {
            var indexedVideoAssetSourceTasks = [Task<IndexedAVAsset?, Error>]()
            
            rawVideoAssets.enumerateObjects { asset, index, _ in
                indexedVideoAssetSourceTasks.append(Task {
                    return try await Self.retrieveAVAssetForPHAsset(asset, index: index, mode: .fastFormat)
                })
            }
            
            var indexedVideoAssetSources = [IndexedAVAsset]()
            for task in indexedVideoAssetSourceTasks {
                if let result = try await task.value {
                    indexedVideoAssetSources.append(result)
                }
                
                assetRetrievalProgressBlock(progressUnit)
            }
            
            return indexedVideoAssetSources.sorted(by: { $0.index < $1.index })
        }
        
        let indexedVideoAssets = try await withThrowingTaskGroup(of: VideoAsset.self) { group in
            let videoAssetSources = try await videoAssetSourcesTask.value
            for item in videoAssetSources {
                group.addTask {
                    let indexedVideoAsset = try await Self.generateVideoAsset(from: item)
                    
                    assetProcessingProgressBlock(progressUnit)
                    return indexedVideoAsset
                }
            }
            
            return try await group.reduce(into: []) {
                $0.append($1)
            }
        }
        
        return indexedVideoAssets.sorted(by: { $0.index < $1.index })
    }
    
    nonisolated func getAllPhotosOfAlbum(_ photoAlbum: PhotoAlbum,
                                         to fetchReason: AlbumFetchingReason,
                                         progressBlock: @escaping @Sendable () -> Void)
    async throws -> [ProgressImage] {
        try await handleAuthorizationStatus()
        
        let album = try self.assetCollectionForAlbum(photoAlbum)
        let assets = PHAsset.fetchAssets(in: album, options: .imagesInAlbum)
        
        let indexedPhotos = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var _indexedPhotos = [(index: Int, image: ProgressImage)]()
                
                assets.enumerateObjects { asset, index, _ in
                    var imageRequestOptions: PHImageRequestOptions
                    switch fetchReason {
                    case .display:
                        imageRequestOptions = .thumbnail
                    case .process:
                        imageRequestOptions = .detailed
                    }
                    
                    imageRequestOptions.isSynchronous = true
                    
                    // Must invoke this block in an autoreleasepool otherwise CGImages backing up the UIImage pile up and memory
                    // consumption keeps growing.
                    autoreleasepool { () -> Void in
                        PHImageManager.default()
                            .requestImageDataAndOrientation(for: asset, options: imageRequestOptions) { data, _, _, resultInfo in
                                defer { Task {
                                    progressBlock()
                                }}
                                
                                guard
                                    let data,
                                    let uiImage = UIImage(data: data),
                                    let thumbnail = uiImage.preparingThumbnail(of: CGSize(width: 640, height: 640))
                                else {
                                    let info = resultInfo ?? [:]
                                    PRLogger.photoLibraryManagement.error("Image could not be loaded! \(info.debugDescription)")
                                    
                                    return
                                }
                                
                                let image = Image(uiImage: thumbnail)
                                
                                // Immediately deallocate objects to free memory
                                
                                let progressImage = ProgressImage(image: image,
                                                                  localIdentifier: asset.localIdentifier,
                                                                  originalSize: CGSize(width: asset.pixelWidth,
                                                                                       height: asset.pixelHeight))
                                _indexedPhotos.append((index, progressImage))
                            }
                    }
                }
                
                continuation.resume(returning: _indexedPhotos)
            }
        }
        
        return indexedPhotos
            .sorted(by: { $0.index < $1.index })
            .map { $0.image }
    }
    
    /// Returns an object that contains all albums from the user's Photo Library that has at least one image.
    nonisolated func getPhotoAlbumCollection() async throws -> PhotoAlbumCollection {
        try await handleAuthorizationStatus()
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        
        var tasks = [Task<PhotoAlbum?, Never>]()
        assetCollections.enumerateObjects { assetCollection, index, _ in
            tasks.append(Task {
                let name = assetCollection.localizedTitle ?? "[Anonymous Album]"
                
                let assets = PHAsset.fetchAssets(in: assetCollection, options: .imagesInAlbum)
                guard let thumbnailAsset = assets.firstObject else {
                    PRLogger.photoLibraryManagement.notice("Library \(name, privacy: .private(mask: .hash)) has no images, skipping it.")
                    return nil
                }
                
                return await withCheckedContinuation { imageContinuation in
                    let requestOptions = PHImageRequestOptions.thumbnail
                    
                    PHImageManager
                        .default()
                        .requestImageDataAndOrientation(for: thumbnailAsset, options: requestOptions) { data, _, _, resultInfo in
                            if data == nil {
                                let info = resultInfo ?? [:]
                                PRLogger.photoLibraryManagement.error("Image data could not be loaded! \(info.debugDescription)")
                            }
                            
                            var image: Image?
                            if  let data,
                                let uiImage = UIImage(data: data)?.preparingThumbnail(of: CGSize(width: 360, height: 360)) {
                                image = Image(uiImage: uiImage)
                            }
                            
                            let photoAlbum = PhotoAlbum(index: index,
                                                        imageCount: assets.count,
                                                        photoKitIdentifier: assetCollection.localIdentifier,
                                                        name: name,
                                                        thumbnailImage: image)
                            imageContinuation.resume(returning: photoAlbum)
                        }
                }
            })
        }
        
        let albumCollection = PhotoAlbumCollection()
        for task in tasks {
            guard let resultAlbum = await task.value else {
                continue
            }
            
            await albumCollection.append(resultAlbum)
        }
        
        return albumCollection
    }
    
    /// Returns the corresponding `PHAssetCollection` for the album.
    nonisolated func assetCollectionForAlbum(_ album: PhotoAlbum) throws -> PHAssetCollection {
        let albumInArray = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [album.photoKitIdentifier], options: nil)
        
        guard let album = albumInArray.firstObject else {
            PRLogger.photoLibraryManagement.error("Album with localIdentifier not found!")
            throw OperationError.albumNotFoundWithLocalIdentifier
        }
        
        return album
    }
    
    func assetForIdentifier(_ identifier: String) throws -> PHAsset {
        let assetInArray = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        
        guard let asset = assetInArray.firstObject else {
            PRLogger.photoLibraryManagement.error("Asset with localIdentifier not found!")
            throw OperationError.assetNotFoundWithLocalIdentifier
        }
        
        return asset
    }
    
    nonisolated func assetsForIdentifiers(_ identifiers: [String]) -> PHFetchResult<PHAsset> {
        return PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
    }
    
    func getAVAsset(for localIdentifier: String) async throws -> AVAsset {
        let phAsset = try assetForIdentifier(localIdentifier)
        let avAssetWithIndex = try await Self.retrieveAVAssetForPHAsset(phAsset, index: -1, mode: .highQualityFormat)
        
        return avAssetWithIndex.asset
    }
    
    // MARK: - Saving video to designated album
    @discardableResult
    func saveProgressVideoToPhotoLibrary(_ progressVideo: ProgressVideo) async throws -> PersistentIdentifier? {
        try await handleAuthorizationStatus()
        
        if self.getPROgressMediaLibraryAssetCollection() == nil {
            try await self.createPROgressMediaLibrary()
        }
        
        let newAssetlocalIdentifier = String.makeActorized()
        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable [newAssetlocalIdentifier, progressVideo] in
                guard let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: progressVideo.url) else {
                    PRLogger.photoLibraryManagement.error("Could not build asset creation request for url \(progressVideo.url, privacy: .private(mask: .hash))")
                    return
                }
                
                guard let videoLibrary = self.getPROgressMediaLibraryAssetCollection() else {
                    PRLogger.photoLibraryManagement.fault("Video library should exist!")
                    return
                }
                
                guard let placeholder = creationRequest.placeholderForCreatedAsset else {
                    PRLogger.photoLibraryManagement.error("Asset creation request has no placeholder!")
                    return
                }
                
                guard let addAssetRequest = PHAssetCollectionChangeRequest(for: videoLibrary) else {
                    PRLogger.photoLibraryManagement.error("Asset addition request failed!")
                    return
                }
                
                addAssetRequest.addAssets([placeholder] as NSArray)
                Task {
                    await newAssetlocalIdentifier.set(to: placeholder.localIdentifier)
                }
            }
            
            let model = await progressVideo.model(withLocalIdentifier: newAssetlocalIdentifier.value)
            try container?.withNewContext {
                $0.insert(model)
                try $0.save()
            }
            
            NotificationCenter.default.post(name: .didCreateNewProgressVideo, object: nil)
            return model.persistentModelID
        } catch let error {
            PRLogger.photoLibraryManagement.error("Failed to save video to PROgress media library! [\(error)]")
            throw OperationError.videoSaveFailed(underlyingError: error)
        }
    }
    
    func createPROgressMediaLibrary() async throws {
        guard self.getPROgressMediaLibraryAssetCollection() == nil else {
            PRLogger.photoLibraryManagement.notice("Video library should not exist to create it!")
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.videoLibraryTitle)
            }
        } catch let error {
            PRLogger.photoLibraryManagement.error("Failed to create the PROgress media library! [\(error)]")
            throw OperationError.videoLibraryCreationFailed(underlyingError: error)
        }
    }
    
    // MARK: - Removing videos from album
    func deleteVideoAssetsFromPROgressLibrary(assets: [VideoAsset]) async throws {
        let localIdentifiersToDelete = assets.map { $0.localIdentifier }
        
        do {
            try await PHPhotoLibrary.shared().performChanges { @Sendable [localIdentifiersToDelete] in
                if self.getPROgressMediaLibraryAssetCollection() == nil {
                    PRLogger.photoLibraryManagement.fault("Video library should exist!")
                    return
                }
                
                let assetsToDelete = self.assetsForIdentifiers(localIdentifiersToDelete)
                PHAssetChangeRequest.deleteAssets(assetsToDelete)
            }
            
            try container?.withNewContext {
                try $0.delete(model: ProgressVideo.Model.self,
                              where: .matchingLocalIdentifiers(localIdentifiersToDelete))
                try $0.save()
                PRLogger.persistence.info("Removed \(localIdentifiersToDelete.count) videos from backing store!")
            }
            
            NotificationCenter.default.post(name: .didRemoveProgressVideos, object: nil)
        } catch let error {
            PRLogger.photoLibraryManagement.error("Failed to remove videos completely! [\(error)]")
            throw OperationError.videoDeletionFailed
        }
    }
    
    // MARK: - Miscellaneous
    func requestAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    private func handleAuthorizationStatus() async throws {
        switch self.authorizationStatus {
        case .notDetermined:
            PRLogger.photoLibraryManagement.notice("saveAssetToPhotoLibrary was called with undetermined status!")
            await self.requestAuthorization()
            
            try await handleAuthorizationStatus()
            
        case .restricted, .denied:
            throw AuthorizationError.deniedAuthorization
            
        case .authorized, .limited:
            break
            
        @unknown default:
            throw AuthorizationError.unknown
        }
    }
    
    private static func generateVideoAsset(from indexedAvAsset: IndexedAVAsset) async throws -> VideoAsset {
        typealias IndexedImage = (index: CMTime, image: UIImage?)
        
        let imageGenerator = AVAssetImageGenerator(asset: indexedAvAsset.asset)
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.maximumSize = .thumbnail
        
        let (videoLength, creationDateMetaData) = try await indexedAvAsset.asset.load(.duration, .creationDate)
        let creationDate = try await creationDateMetaData?.load(.dateValue)
        
        let times = (0...4).map {
            CMTime(seconds: videoLength.seconds / 4 * Double($0),
                   preferredTimescale: 1)
        }
        
        var indexedImages = [IndexedImage]()
        for await imageGeneratorResult in imageGenerator.images(for: times) {
            switch imageGeneratorResult {
            case let .success(_, image, actualTime):
                indexedImages.append((index: actualTime, image: UIImage(cgImage: image)))
                
            case let .failure(requestedTime, _):
                indexedImages.append((index: requestedTime, image: nil))
            }
        }
        
        let thumbnails = indexedImages
            .sorted(by: { $0.index < $1.index })
            .map { $0.image}
        
        return VideoAsset(firstImage: thumbnails[0],
                          middleImages: Array(thumbnails[1...3]),
                          lastImage: thumbnails[4],
                          length: videoLength.seconds,
                          index: indexedAvAsset.index,
                          creationDate: creationDate,
                          localIdentifier: indexedAvAsset.localIdentifier)
    }
    
    private static func retrieveAVAssetForPHAsset(_ phAsset: PHAsset, 
                                                  index: Int,
                                                  mode: PHVideoRequestOptionsDeliveryMode)
    async throws -> IndexedAVAsset {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<IndexedAVAsset, Error>) in
            let requestOptions = PHVideoRequestOptions()
            requestOptions.deliveryMode = mode
            requestOptions.version = .current
            
            PHImageManager.default()
                .requestAVAsset(forVideo: phAsset, options: requestOptions) { avAsset, _, resultInfo in
                    guard let avAsset else {
                        let info = resultInfo ?? [:]
                        PRLogger.photoLibraryManagement.error("Video could not be loaded! \(info.debugDescription)")
                        
                        continuation.resume(throwing: OperationError.videoNotFound)
                        return
                    }

                    let indexedAsset = IndexedAVAsset(asset: avAsset,
                                                      localIdentifier: phAsset.localIdentifier,
                                                      index: index)
                    continuation.resume(returning: indexedAsset)
                }
        }
    }
    
    enum AlbumFetchingReason {
        /// Retrieve images to show thumbnails of them.
        ///
        /// Performance-optimized details should be requested in this mode.
        case display
        
        /// Retrieve images to process them.
        ///
        /// Maximum details should be requested in this mode.
        case process
    }
    
    // MARK: - Error types
    enum OperationError: Error {
        case albumNotFoundWithLocalIdentifier
        case assetNotFoundWithLocalIdentifier
        case videoDeletionFailed
        case videoNotFound
        case videoLibraryCreationFailed(underlyingError: Error)
        case videoLibraryNotFound
        case videoSaveFailed(underlyingError: Error)
    }
    
    enum AuthorizationError: Error {
        /// The user has denied access to the photo library. Photo management is not possible.
        case deniedAuthorization
        
        /// The authorization value was added in a later OS version. Photo management will err on the safe side and will not happen.
        case unknown
    }
}
