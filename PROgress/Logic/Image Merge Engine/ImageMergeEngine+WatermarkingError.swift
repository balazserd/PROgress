//
//  ImageMergeEngine+WatermarkingError.swift
//  PROgress
//
//  Created by Balázs Erdész on 03/06/2024.
//

import Foundation

extension ImageMergeEngine {
    enum WatermarkingError: Error {
        case watermarkIconMissingInBundle
        case watermarkBackgroundFilterFailure
        case watermarkTextFilterFailure
    }
}
