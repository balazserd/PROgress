//
//  CoreImage+Sendable.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 25..
//

import Foundation
import CoreImage

// Apple states that `CIImage` and `CIContext` are thread safe: https://developer.apple.com/documentation/coreimage/ciimage
// > "CIContext and CIImage objects are immutable, which means each can be shared safely among threads."
extension CIImage: @unchecked Sendable { }
extension CIContext: @unchecked Sendable { }
