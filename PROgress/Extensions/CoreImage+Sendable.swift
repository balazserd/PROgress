//
//  CoreImage+Sendable.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 25..
//

import Foundation
import CoreImage

// Apple states that `CIImage` and `CIContext` are immutable and can be shared safely among threads.
extension CIImage: @unchecked Sendable { }
extension CIContext: @unchecked Sendable { }
