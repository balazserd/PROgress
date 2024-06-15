//
//  VideoAsset.swift
//  PROgress
//
//  Created by Balázs Erdész on 07/05/2024.
//

import Foundation
import UIKit

struct VideoAsset: Hashable, Sendable {
    var firstImage: UIImage?
    var middleImages: [UIImage?]
    var lastImage: UIImage?
    var name: String = "Progress Video"
    var length: Double
    var index: Int
    var creationDate: Date?
    var localIdentifier: String
}

extension Array where Element == VideoAsset {
    mutating func addAssetNamesFromPersistentStore(persistedAssets: [ProgressVideo.Model]) {
        for (index, asset) in self.enumerated() {
            if let model = persistedAssets.first(where: { $0.localIdentifier == asset.localIdentifier }) {
                self[index].name = model.name
            } else {
                self[index].name = "Progress Video"
            }
        }
    }
}
