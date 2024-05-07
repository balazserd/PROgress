//
//  IndexedAVAsset.swift
//  PROgress
//
//  Created by Balázs Erdész on 07/05/2024.
//

import Foundation
import AVFoundation

struct IndexedAVAsset: @unchecked Sendable {
    let asset: AVAsset
    let localIdentifier: String
    var index: Int
}
