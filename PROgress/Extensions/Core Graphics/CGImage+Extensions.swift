//
//  CGImage+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/04/2024.
//

import Foundation
import UIKit
import CoreGraphics

extension CGImage {
    func thumbnail(ofSize size: CGSize = .thumbnail) async -> UIImage? {
        return await UIImage(cgImage: self).byPreparingThumbnail(ofSize: size)
    }
}

extension CGSize {
    static var thumbnail: CGSize { .init(width: 240, height: 240) }
}
