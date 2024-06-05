//
//  AlbumSelectorView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 17..
//

import SwiftUI

struct AlbumSelectorView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var viewModel: NewProgressVideoViewModel
    
    @Binding var selectedAlbum: PhotoAlbum?
    
    var body: some View {
        NavigationStack {
            VStack {
                switch viewModel.photoAlbumsLoadingState {
                case .success(let albums):
                    ScrollView {
                        VStack {
                            LazyVGrid(columns: Array(repeating: .init(spacing: 14), count: gridColumnCount),
                                      spacing: 16) {
                                ForEach(albums, id: \.index) { album in
                                    AlbumSelectorGridItem(album: album)
                                        .onTapGesture {
                                            selectedAlbum = album
                                            dismiss()
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                case .loading:
                    ProgressView() {
                        Text("Loading your Photos folders...")
                    }
                    
                case .failure:
                    Text("Failed to load albums!")
                    
                default: EmptyView()
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

struct AlbumSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        AlbumSelectorView(selectedAlbum: .constant(nil))
    }
}
