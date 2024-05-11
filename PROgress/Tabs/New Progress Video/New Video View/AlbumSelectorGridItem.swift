//
//  AlbumSelectorGridItem.swift
//  PROgress
//
//  Created by Balázs Erdész on 11/05/2024.
//

import SwiftUI

struct AlbumSelectorGridItem: View {
    let album: PhotoAlbum
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fill)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                .overlay {
                    if let image = album.thumbnailImage {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo.circle")
                            .resizable()
                            .scaledToFill()
                            .padding()
                    }
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8))
                .padding(.bottom, 8)
                .padding(.horizontal, -12).padding(.top, -8)
            
            Text(album.name)
                .font(.callout)
                .lineLimit(1)
                .lineSpacing(0.6)
            
            Text("\(album.imageCount)")
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white)
                .shadow(color: .gray.opacity(0.3), radius: 7, x: 0, y: 0)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    let albums: [PhotoAlbum] = [
        .init(index: 1, imageCount: 56, photoKitIdentifier: "fdksgjfdkgfd", name: "Album1", thumbnailImage: nil),
        .init(index: 2, imageCount: 56, photoKitIdentifier: "fdksgjfdkgfd", name: "Album1", thumbnailImage: nil),
        .init(index: 3, imageCount: 56, photoKitIdentifier: "fdksgjfdkgfd", name: "Album1", thumbnailImage: nil),
        .init(index: 4, imageCount: 56, photoKitIdentifier: "fdksgjfdkgfd", name: "Album1", thumbnailImage: nil),
        .init(index: 5, imageCount: 56, photoKitIdentifier: "fdksgjfdkgfd", name: "Album1", thumbnailImage: nil)
    ]
    
    return LazyVGrid(columns: Array(repeating: .init(spacing: 20), count: 2), spacing: 20) {
        ForEach(albums, id: \.index) { album in
            AlbumSelectorGridItem(album: album)
        }
    }
    .padding()
}
