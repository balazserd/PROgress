//
//  PhotoAlbum.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import Foundation
import SwiftUI

struct PhotoAlbum: Sendable {
    var index: Int
    var imageCount: Int
    var photoKitIdentifier: String
    var name: String
    let thumbnailImage: Image?
}
