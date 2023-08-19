//
//  ImageMergeEngine+MergeOptions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation

extension ImageMergeEngine {
    struct MergeOptions {
        /// The resolution the video cannot exceed.
        static let maximumSize = CGSize(width: 2160, height: 2160)
        
        var size: CGSize
        var customOrder: [Int]?
        
        init(size: CGSize, customOrder: [Int]? = nil) {
            let widthScale = min(1.0, Self.maximumSize.width / size.width)
            let heightScale = min(1.0, Self.maximumSize.height / size.height)
            let finalScale = min(widthScale, heightScale)
            
            self.size = size.applying(CGAffineTransform(scaleX: finalScale,
                                                        y: finalScale))
            self.customOrder = customOrder
        }
    }
}
