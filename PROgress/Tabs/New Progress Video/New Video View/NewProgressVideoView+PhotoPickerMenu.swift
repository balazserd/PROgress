//
//  NewProgressVideoView+PhotoSelectionMenu.swift
//  PROgress
//
//  Created by Balázs Erdész on 26/08/2024.
//

import SwiftUI

extension NewProgressVideoView {
    struct PhotoSelectionMenu<Content: View>: View {
        @EnvironmentObject var viewModel: NewProgressVideoViewModel
        
        @Binding var isShowingPhotoPicker: Bool
        @Binding var isShowingPhotoAlbumPicker: Bool
        
        @ViewBuilder var label: () -> Content
        
        var body: some View {
            Menu {
                Button(action: { isShowingPhotoPicker = true }) {
                    Label("Select photos", systemImage: "photo.stack")
                }
                
                Button(action: {
                    isShowingPhotoAlbumPicker = true
                    viewModel.loadPhotoAlbums()
                }) {
                    Label("Select a folder", systemImage: "folder")
                }
            } label: {
                label()
            }
        }
    }
}
