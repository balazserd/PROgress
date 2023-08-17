//
//  NewProgressVideoView+AlbumSelectorView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 17..
//

import SwiftUI

extension NewProgressVideoView {
    struct AlbumSelectorView: View {
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        @Environment(\.verticalSizeClass) var verticalSizeClass
        @Environment(\.dismiss) var dismiss
        
        @EnvironmentObject var viewModel: NewProgressVideoViewModel
        
        @Binding var selectedAlbum: PhotoAlbum?
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack {
                        switch viewModel.photoAlbumsLoadingState {
                        case .success(let albums):
                            LazyVGrid(columns: Array(repeating: .init(spacing: 14), count: gridColumnCount),
                                      spacing: 16) {
                                ForEach(albums, id: \.index) { album in
                                    VStack(alignment: .leading, spacing: 0) {
                                        Rectangle()
                                            .aspectRatio(1, contentMode: .fill)
                                            .overlay {
                                                (album.thumbnailImage ?? Image(systemName: "photo.circle"))
                                                    .resizable()
                                                    .scaledToFill()
                                            }
                                            .clipped()
                                            .cornerRadius(4)
                                            .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                                            .padding(.bottom, 4)
                                            .onTapGesture {
                                                selectedAlbum = album
                                                dismiss()
                                            }
                                        
                                        Text(album.name)
                                            .font(.callout)
                                            .lineLimit(1)
                                            .lineSpacing(0.6)
                                        
                                        Text("\(album.imageCount)")
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 6)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        case .loading:
                            ProgressView()
                            
                        case .failure:
                            Text("Failed to load albums!")
                            
                        default: EmptyView()
                        }
                    }
                }
                .navigationTitle("Select an album")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: { dismiss() })
                    }
                }
            }
        }
        
        private var gridColumnCount: Int {
            guard self.horizontalSizeClass == .compact else { return 4 }
            
            return self.verticalSizeClass == .regular ? 2 : 4
        }
    }
}

struct NewProgressVideoView_AlbumSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView.AlbumSelectorView(selectedAlbum: .constant(nil))
    }
}
