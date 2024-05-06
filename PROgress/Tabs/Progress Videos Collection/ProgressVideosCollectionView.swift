//
//  ProgressVideosCollectionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import SwiftUI

struct ProgressVideosCollectionView: View {
    @StateObject private var viewModel = ProgressVideosCollectionViewModel()
    
    @State private var isEditing: Bool = false
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationState) {
            ScrollView {
                if let videos = viewModel.videos {
                    VStack {
                        if videos.count == 0 {
                            ContentUnavailableView("No videos",
                                                   systemImage: "questionmark.folder.fill",
                                                   description: Text("New progress videos you create will appear here."))
                        } else if viewModel.searchCriteriaFulfillingVideos.count == 0 {
                            ContentUnavailableView("No match",
                                                   systemImage: "questionmark.folder.fill",
                                                   description: Text("No video matches your search."))
                        } else {
                            ProgressVideoCollectionGrid {
                                ForEach(viewModel.searchCriteriaFulfillingVideos, id: \.index) { video in
                                    ProgressVideoCollectionItem(video: video, isEditing: $isEditing)
                                        .environmentObject(viewModel)
                                        .onTapGesture {
                                            if isEditing {
                                                viewModel.toggleDeletionStatus(for: video)
                                            } else {
                                                viewModel.navigationState.append(video)
                                            }
                                        }
                                        .onLongPressGesture {
                                            isEditing.toggle()
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
                    Text("Loading videos...")
                }
            }
            .searchable(text: $viewModel.searchText)
            .toolbar { toolbar }
            .navigationTitle("Progress Videos")
            .navigationDestination(for: VideoAsset.self) { asset in
                ProgressVideoPlayerView(video: asset)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.deleteMarkedVideos() }) {
                    Image(systemName: "checkmark.circle.badge.xmark")
                        .symbolRenderingMode(.multicolor)
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
            Button(action: { isEditing.toggle() }) {
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
