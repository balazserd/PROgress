//
//  NewProgressVideoView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI
import PhotosUI
import Combine
import CoreData
import AVKit

struct NewProgressVideoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isReordering: Bool = false
    @State private var draggedImage: ProgressImage?
    
    @State private var isShowingPhotoPicker: Bool = false
    @State private var isShowingPhotoAlbumPicker: Bool = false
    
    @State private var editedVideoName: String = ""
    
    @StateObject private var viewModel = NewProgressVideoViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack(path: $viewModel.navigationState) {
                VStack {
                    switch viewModel.imageLoadingState {
                    case .undefined:
                        photoSelectionMenu {
                            Text("Select photos")
                        }
                        
                    case .loading(let progress):
                        loadingView(progress)
                        
                    case .failure:
                        ContentUnavailableView {
                            Label("Loading the image failed!", systemImage: "xmark.circle.fill")
                        } description: {
                            Text("Try restarting the app.")
                                .foregroundStyle(.secondary)
                        }
                        
                    case .success:
                        VideoSettingsView()
                    }
                }
                .toolbar { toolbar }
                .navigationTitle($viewModel.videoName)
                .navigationBarTitleDisplayMode(.inline)
                .photosPicker(isPresented: $isShowingPhotoPicker,
                              selection: $viewModel.selectedItems,
                              matching: .any(of: [.images, .screenshots]))
                .sheet(isPresented: $isShowingPhotoAlbumPicker,
                       onDismiss: { isShowingPhotoAlbumPicker = false }) {
                    AlbumSelectorView(selectedAlbum: $viewModel.selectedAlbum)
                }
            }
                
            switch viewModel.videoProcessingState {
            case .idle:
                EmptyView()
                
            case .working(let progress):
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VideoProcessingInProgressView(progress: progress)
                    .transition(.opacity.animation(.linear(duration: 0.3)))
                
            case .finished:
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture(perform: { viewModel.resetVideoProcessingState() })
                
                VideoProcessingFinishedView(action: { viewModel.watchVideo() })
                    .transition(.opacity.animation(.linear(duration: 0.3)))
            }
        }
        .environmentObject(self.viewModel)
    }
    
    // MARK: - Subviews
    private func loadingView(_ progress: Double) -> some View {
        VStack(alignment: .leading) {
            ProgressView(value: progress) {
                Text("Importing photos...")
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Depending on the number of selected photos, this operation might take a few minutes.")
                Text("If photos are only available in iCloud, the operation's length will also depend on your download speed.")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func photoSelectionMenu<Content: View>(@ViewBuilder label: () -> Content) -> some View {
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
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            photoSelectionMenu {
                Image(systemName: "plus")
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
}

// MARK: - Preview
struct NewProgressVideoView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView()
    }
}
