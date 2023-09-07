//
//  ImageMergeEngine+MergeError.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation

extension ImageMergeEngine {
    enum MergeError: Error {
        case assetWriterStartFailure
        case ciImageCreationFailure
        case dataConversionFailure
        case missingPixelBufferPool
        case missingSample
        case pixelBufferCreationError
        case taskNotFound
        case unknown
    }
}
