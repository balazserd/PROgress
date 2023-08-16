//
//  PhotoLibraryManager.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import Photos

class PhotoLibraryManager {
    var authorizationStatus: PHAuthorizationStatus
    
    static let videoLibraryTitle = "PROgress"
    
    init() {
        self.authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    }
    
    /// The PROgress app's designated video folder.
    var videoLibraryAssetCollection: PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title LIKE %@", Self.videoLibraryTitle)
        
        let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            
        if assetCollections.count > 1 {
            PRLogger.photoLibraryManagement.fault("Unexpectedly found more than 1 matching libraries!")
        }
        
        return assetCollections.firstObject
    }
    
    /// An object that contains all albums from the user's Photo Library that has at least one image.
    var photoAlbumCollection: PhotoAlbumCollection {
        get async throws {
            let assetCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            
            var tasks = [Task<PhotoAlbum?, Never>]()
            assetCollections.enumerateObjects { assetCollection, index, _ in
                tasks.append(Task {
                    let name = assetCollection.localizedTitle ?? "[Anonymous Album]"
                    
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType LIKE %d", PHAssetMediaType.image.rawValue)
                    
                    let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
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
                                
                                let photoAlbum = PhotoAlbum(index: index, name: name, thumbnailImage: data)
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
    }
    
    func requestAuthorization() async {
        authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
    
    func saveAssetToPhotoLibrary(atUrl url: URL) async throws {
        switch self.authorizationStatus {
        case .notDetermined:
            PRLogger.photoLibraryManagement.notice("saveAssetToPhotoLibrary was called with undetermined status!")
            await self.requestAuthorization()
            
            try await saveAssetToPhotoLibrary(atUrl: url)
            return
            
        case .restricted, .denied:
            throw AuthorizationError.deniedAuthorization
            
        case .authorized, .limited:
            break
            
        @unknown default:
            throw AuthorizationError.unknown
        }
        
        if self.videoLibraryAssetCollection == nil {
            try await self.createPROgressMediaLibrary()
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                guard let creationRequest = PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                    PRLogger.photoLibraryManagement.error("Could not build asset creation request for url \(url, privacy: .private(mask: .hash))")
                    return
                }
                
                guard let videoLibrary = self.videoLibraryAssetCollection else {
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
    
    func createPROgressMediaLibrary() async throws {
        guard self.videoLibraryAssetCollection == nil else {
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
    
    enum OperationError: Error {
        case videoLibraryCreationFailed(underlyingError: Error)
        case videoSaveFailed(underlyingError: Error)
    }
    
    enum AuthorizationError: Error {
        /// The user has denied access to the photo library. Photo management is not possible.
        case deniedAuthorization
        
        /// The authorization value was added in a later OS version. Photo management will err on the safe side and will not happen.
        case unknown
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
}
