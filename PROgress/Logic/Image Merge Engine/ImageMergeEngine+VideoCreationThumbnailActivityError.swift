//
//  ImageMergeEngine+VideoCreationThumbnailActivityError.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation

extension ImageMergeEngine {
    enum VideoCreationThumbnailActivityError: Error {
        case zeroImageCount
        case thumbnailImageCreation
        case appGroupNotFound
    }
}
