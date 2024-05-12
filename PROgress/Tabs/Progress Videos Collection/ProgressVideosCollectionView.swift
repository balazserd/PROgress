//
//  ProgressVideosCollectionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import SwiftUI

struct ProgressVideosCollectionView: View {
    @StateObject private var viewModel = ProgressVideosCollectionViewModel()
    
    @State private var showDeleteConfirmationAlert: Bool = false
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationState) {
            ScrollView {
                if let videos = viewModel.videos {
                    VStack {
                        if videos.count == 0 {
                            ContentUnavailableView("No videos",
                                                   systemImage: "questionmark.folder.fill",
                                                   description: Text("New progress videos you create will appear here."))
                                .padding(.top, 50)
                        } else if viewModel.searchCriteriaFulfillingVideos.count == 0 {
                            ContentUnavailableView("No match",
                                                   systemImage: "questionmark.folder.fill",
                                                   description: Text("No video matches your search."))
                                .padding(.top, 50)
                        } else {
                            ProgressVideoCollectionGrid {
                                ForEach(viewModel.searchCriteriaFulfillingVideos, id: \.index) { video in
                                    ProgressVideoCollectionItem(video: video, isEditing: $viewModel.isEditing)
                                        .environmentObject(viewModel)
                                        .onTapGesture {
                                            if viewModel.isEditing {
                                                viewModel.toggleDeletionStatus(for: video)
                                            } else {
                                                viewModel.navigationState.append(video)
                                            }
                                        }
                                        .onLongPressGesture {
                                            viewModel.isEditing.toggle()
                                        }
                                }
                            }
                            .padding([.horizontal], 20)
                        }
                    }
                    .searchable(text: $viewModel.searchText)
                    .refreshable {
                        viewModel.loadProgressVideos()
                    }
                    .padding(.top, 12)
                } else {
                    ProgressView()
                        .padding(.top, 20)
                    
                    Text("Loading videos...")
                }
            }
            .searchable(text: $viewModel.searchText)
            .toolbar { toolbar }
            .navigationTitle("Progress Videos")
            .navigationDestination(for: VideoAsset.self) { asset in
                ProgressVideoPlayerView(video: asset)
            }
            .alert("Delete videos?", isPresented: $showDeleteConfirmationAlert) {
                Button(role: .destructive, action: { viewModel.deleteMarkedVideos() }) {
                    Text("Delete")
                }
                
                Button(role: .cancel, action: { showDeleteConfirmationAlert = false }) {
                    Text("Cancel").fixedSize()
                }
            } message: {
                Text("The videos will also be deleted from the designated media library for PROgress in the Photos app.\n\nDeleted videos can be recovered in the Photos app for a period of time set by your operating system.")
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if viewModel.isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .destructive, action: { showDeleteConfirmationAlert = true }) {
                    Image(systemName: "trash")
                        .tint(.red)
                        .offset(x: -2, y: 2)
                }
                .disabled(viewModel.videosToDelete.count == 0)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.videosToDelete.removeAll() }) {
                    Image(systemName: "slider.horizontal.2.gobackward")
                }
                .disabled(viewModel.videosToDelete.count == 0)
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: { viewModel.isEditing.toggle() }) {
                Image(systemName: "slider.horizontal.3")
            }
        }
    }
}

struct ProgressVideosCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressVideosCollectionView()
    }
}
