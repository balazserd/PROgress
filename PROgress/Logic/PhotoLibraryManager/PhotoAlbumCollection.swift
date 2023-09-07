//
//  PhotoAlbumCollection.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import Foundation

actor PhotoAlbumCollection {
    var photoAlbums: [PhotoAlbum] = []
    
    func append(_ newAlbum: PhotoAlbum) {
        photoAlbums.append(newAlbum)
    }
}
