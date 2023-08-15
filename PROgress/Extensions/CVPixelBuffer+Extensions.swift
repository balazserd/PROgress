//
//  CVPixelBuffer+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import CoreVideo

extension CVPixelBuffer {
    /// Locks the pixel buffer, then clears it with black pixels.
    ///
    /// - Important: When using the buffer from a `CVPixelBufferPool` and for delayed operations, like appending the buffer to an `AVAssetWriterInputPixelBufferAdaptor`, you must call this method **before** using the buffer, not after being done using the buffer.
    func lockAndClear() {
        CVPixelBufferLockBaseAddress(self, [])
        memset_pattern16(CVPixelBufferGetBaseAddress(self),
                         [0, 0, 0, 0xFF],
                         CVPixelBufferGetBytesPerRow(self) * CVPixelBufferGetHeight(self))
    }
    
    func unlock() {
        CVPixelBufferUnlockBaseAddress(self, [])
    }
}
