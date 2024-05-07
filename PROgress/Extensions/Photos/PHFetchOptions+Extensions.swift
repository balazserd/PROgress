//
//  PHFetchOptions+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 07/05/2024.
//

import Foundation
import Photos

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
