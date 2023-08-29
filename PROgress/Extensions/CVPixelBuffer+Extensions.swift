//
//  CVPixelBuffer+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import CoreVideo
import Accelerate

extension CVPixelBuffer {
    /// Locks the pixel buffer, then clears it with white pixels.
    ///
    /// - Important: When using the buffer from a `CVPixelBufferPool` and for delayed operations, like appending the buffer to an `AVAssetWriterInputPixelBufferAdaptor`, you must call this method **before** using the buffer, not after being done using the buffer.
    func lockAndClear() {
        CVPixelBufferLockBaseAddress(self, [])
        
        var buffer = vImage_Buffer(data: CVPixelBufferGetBaseAddress(self),
                                   height: vImagePixelCount(CVPixelBufferGetHeight(self)),
                                   width: vImagePixelCount(CVPixelBufferGetWidth(self)),
                                   rowBytes: CVPixelBufferGetBytesPerRow(self))

        let error = vImageBufferFill_ARGB8888(&buffer, [0xFF, 0xFF, 0xFF, 0xFF], vImage_Flags(kvImageNoFlags))
        if error != kvImageNoError {
            PRLogger.imageProcessing.error("Image Buffer could not be filled! [\(error)]")
        }
        
//        memset_pattern16(CVPixelBufferGetBaseAddress(self),
//                         [0, 0, 0, 0xFF],
//                         CVPixelBufferGetBytesPerRow(self) * CVPixelBufferGetHeight(self))
    }
    
    func unlock() {
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}
