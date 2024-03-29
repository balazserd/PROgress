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

actor PhotoLibraryManager {
    var authorizationStatus: PHAuthorizationStatus
    
    static let videoLibraryTitle = "PROgress"
    
    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    // MARK: - Working with albums
    /// The PROgress app's designated video folder.
    nonisolated var PROgressMediaLibraryAssetCollection: PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title LIKE %@", Self.videoLibraryTitle)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            
        if assetCollections.count > 1 {
            PRLogger.photoLibraryManagement.fault("Unexpectedly found more than 1 matching libraries!")
        }
        
        return assetCollections.firstObject
    }
    
    /// Returns all videos in the PROgress app's designated video folder.
    nonisolated func getAllVideosOfPROgressMediaLibrary(
        retrieval assetRetrievalProgressBlock: @escaping @Sendable (Double) -> Void,
        processing assetProcessingProgressBlock: @escaping @Sendable (Double) -> Void
    ) async throws -> [VideoAsset] {
        guard let videoLibrary = PROgressMediaLibraryAssetCollection else {
            PRLogger.photoLibraryManagement.error("Did not find the designated video library!")
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
            var indexedVideoAssetSourceTasks = [Task<IndexedAVAsset, Never>]()
            
            rawVideoAssets.enumerateObjects { asset, index, _ in
                indexedVideoAssetSourceTasks.append(Task {
                    return await withCheckedContinuation { continuation in
                        let requestOptions = PHVideoRequestOptions()
                        requestOptions.deliveryMode = .fastFormat
                        requestOptions.version = .current
                        
                        PHImageManager.default()
                            .requestAVAsset(forVideo: asset, options: requestOptions) { avAsset, _, resultInfo in
                                defer { Task {
                                    assetRetrievalProgressBlock(progressUnit)
                                }}
    
                                guard let avAsset else {
                                    let info = resultInfo ?? [:]
                                    PRLogger.photoLibraryManagement.error("Video could not be loaded! \(info.debugDescription)")
    
                                    return
                                }
    
                                let indexedAsset = IndexedAVAsset(asset: avAsset, index: index)
                                continuation.resume(returning: indexedAsset)
                            }
                    }
                })
            }
            
            var indexedVideoAssetSources = [IndexedAVAsset]()
            for task in indexedVideoAssetSourceTasks {
                let result = await task.value
                indexedVideoAssetSources.append(result)
            }
            
            return indexedVideoAssetSources.sorted(by: { $0.index < $1.index })
        }
        
        let indexedVideoAssets = try await withThrowingTaskGroup(of: VideoAsset.self) { group in
            let videoAssetSources = await videoAssetSourcesTask.value
            for item in videoAssetSources {
                group.addTask {
                    let imageGenerator = AVAssetImageGenerator(asset: item.asset)
                    
                    let (videoLength, creationDateMetaData) = try await item.asset.load(.duration, .creationDate)
                    let creationDate = try await creationDateMetaData?.load(.dateValue)
                    let firstImage = try await imageGenerator.image(at: .zero).image
                    let lastImage = try await imageGenerator.image(at: videoLength).image
                    
                    assetProcessingProgressBlock(progressUnit)
                    return VideoAsset(firstImage: UIImage(cgImage: firstImage),
                                      lastImage: UIImage(cgImage: lastImage),
                                      length: videoLength.seconds,
                                      index: item.index,
                                      creationDate: creationDate)
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
                            let progressImage = ProgressImage(image: image,
                                                              localIdentifier: asset.localIdentifier,
                                                              originalSize: CGSize(width: asset.pixelWidth,
                                                                                   height: asset.pixelHeight))
                            _indexedPhotos.append((index, progressImage))
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
    
    nonisolated func assetForIdentifier(_ identifier: String) throws -> PHAsset {
        let assetInArray = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        
        guard let asset = assetInArray.firstObject else {
            PRLogger.photoLibraryManagement.error("Asset with localIdentifier not found!")
            throw OperationError.assetNotFoundWithLocalIdentifier
        }
        
        return asset
    }
    
    // MARK: - Saving video to designated album
    nonisolated func saveAssetToPhotoLibrary(assetAtUrl url: URL) async throws {
        switch await self.authorizationStatus {
        case .notDetermined:
            PRLogger.photoLibraryManagement.notice("saveAssetToPhotoLibrary was called with undetermined status!")
            await self.requestAuthorization()
            
            try await saveAssetToPhotoLibrary(assetAtUrl: url)
            return
            
        case .restricted, .denied:
            throw AuthorizationError.deniedAuthorization
            
        case .authorized, .limited:
            break
            
        @unknown default:
            throw AuthorizationError.unknown
        }
        
        if self.PROgressMediaLibraryAssetCollection == nil {
            try await self.createPROgressMediaLibrary()
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                guard let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                    PRLogger.photoLibraryManagement.error("Could not build asset creation request for url \(url, privacy: .private(mask: .hash))")
                    return
                }
                
                guard let videoLibrary = self.PROgressMediaLibraryAssetCollection else {
                    PRLogger.photoLibraryManagement.fault("PROgress video library asset collection not found!")
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
            }
        } catch let error {
            PRLogger.photoLibraryManagement.error("Failed to save video to PROgress media library! [\(error)]")
            throw OperationError.videoSaveFailed(underlyingError: error)
        }
    }
    
    nonisolated func createPROgressMediaLibrary() async throws {
        guard self.PROgressMediaLibraryAssetCollection == nil else {
            PRLogger.photoLibraryManagement.fault("Attempted to recreate the PROgress video library!")
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: Self.videoLibraryTitle)
            }
        } catch let error {
            PRLogger.photoLibraryManagement.error("Failed to create the PROgress media library! [\(error)]")
            throw OperationError.videoLibraryCreationFailed(underlyingError: error)
        }
    }
    
    // MARK: - Miscellaneous
    func requestAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
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
        case videoLibraryCreationFailed(underlyingError: Error)
        case videoLibraryNotFound
        case videoSaveFailed(underlyingError: Error)
        case albumNotFoundWithLocalIdentifier
        case assetNotFoundWithLocalIdentifier
    }
    
    enum AuthorizationError: Error {
        /// The user has denied access to the photo library. Photo management is not possible.
        case deniedAuthorization
        
        /// The authorization value was added in a later OS version. Photo management will err on the safe side and will not happen.
        case unknown
    }
}

extension PHFetchOptions {
    /// The `PHFetchOptions` object that wants to fetch only images from an asset collection.
    static var imagesInAlbum: Self {
        let fetchOptions = Self()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        
        return fetchOptions
    }
    
    /// The `PHFetchOptions` object that wants to fetch only videos from an asset collection.
    static var videosInAlbum: Self {
        let fetchOptions = Self()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeCloudShared]
        
        return fetchOptions
    }
}

extension PHImageRequestOptions {
    static var thumbnail: Self {
        let requestOptions = Self()
        requestOptions.resizeMode = .fast
        requestOptions.version = .current
        requestOptions.isNetworkAccessAllowed = true
        
        return requestOptions
    }
    
    static var detailed: Self {
        let requestOptions = Self()
        requestOptions.resizeMode = .exact
        requestOptions.version = .current
        requestOptions.isNetworkAccessAllowed = true
        
        return requestOptions
    }
}

struct VideoAsset: Sendable {
    var firstImage: UIImage
    var lastImage: UIImage
    var name: String?
    var length: Double
    var index: Int
    var creationDate: Date?
}

struct IndexedAVAsset: @unchecked Sendable {
    let asset: AVAsset
    var index: Int
}
