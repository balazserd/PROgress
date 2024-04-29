//
//  ProgressVideosCollectionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import SwiftUI

struct ProgressVideosCollectionView: View {
    @StateObject private var viewModel = ProgressVideosCollectionViewModel()
    
    var body: some View {
        NavigationStack {
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
                                    ProgressVideoCollectionItem(video: video)
                                        .environmentObject(viewModel)
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
            .navigationTitle("Progress Videos")
            .navigationDestination(for: VideoAsset.self) { asset in
                ProgressVideoPlayerView(video: asset)
            }
        }
    }
}

struct ProgressVideosCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressVideosCollectionView()
    }
}
