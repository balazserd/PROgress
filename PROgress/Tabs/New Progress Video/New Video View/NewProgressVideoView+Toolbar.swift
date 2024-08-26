//
//  NewProgressVideoView+Toolbar.swift
//  PROgress
//
//  Created by Balázs Erdész on 26/08/2024.
//

import SwiftUI

extension NewProgressVideoView {
    struct Toolbar: ToolbarContent {
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        @Binding var isShowingPhotoPicker: Bool
        @Binding var isShowingPhotoAlbumPicker: Bool
        
        // This warning is fixed with Xcode 16:
        // [Xcode 16] @MainActor @preconcurrency protocol ToolbarContent
        // vs
        // [Xcode 15] protocol ToolbarContent
        var body: some ToolbarContent {
            ToolbarItem(placement: .primaryAction) {
                if viewModel.imageLoadingState.isSuccess {
                    ConfirmationButton()
                } else {
                    PhotoSelectionMenu(isShowingPhotoPicker: $isShowingPhotoPicker,
                                       isShowingPhotoAlbumPicker: $isShowingPhotoAlbumPicker) {
                        Image(systemName: "plus")
                    }
                    .disabled(viewModel.imageLoadingState.isLoading)
                }
            }
            
            if viewModel.progressImages.count > 0 {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.beginMerge() }) {
                        Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                    }
                    .disabled(!viewModel.imageLoadingState.isSuccess)
                }
            }
            
            if viewModel.video != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { viewModel.watchVideo() }) {
                        Image(systemName: "video.fill")
                    }
                }
            }
        }
        
        private struct ConfirmationButton: View {
            @EnvironmentObject private var viewModel: NewProgressVideoViewModel
            
            @State private var isShowingResetProgressImagesConfirmationDialog: Bool = false
            
            var body: some View {
                Button(action: { isShowingResetProgressImagesConfirmationDialog = true }) {
                    Image(systemName: "trash")
                }
                .confirmationDialog("Reset progress images?",
                                    isPresented: $isShowingResetProgressImagesConfirmationDialog,
                                    titleVisibility: .visible) {
                    Button("Reset", role: .destructive) {
                        viewModel.resetProgressImages()
                    }
                    
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action cannot be undone.")
                }
            }
        }
    }
}
