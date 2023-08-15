//
//  ImageMergeEngine+MergeError.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation

extension ImageMergeEngine {
    enum MergeError: Error {
        case unknown
        case dataConversionFailure
        case taskNotFound
        case assetWriterStartFailure
        case missingPixelBufferPool
        case missingSample
        case ciImageCreationFailure
    }
}
