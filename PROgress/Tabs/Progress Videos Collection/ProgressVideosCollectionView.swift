//
//  ProgressVideosCollectionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 16..
//

import SwiftUI

struct ProgressVideosCollectionView: View {
    @StateObject private var viewModel = ProgressVideosCollectionViewModel()
    
    private static var largeProgressImageSize = 80.0
    private static var smallProgressImageSize = 60.0
    
    var body: some View {
        NavigationStack {
            VStack {
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
                            List {
                                ForEach(viewModel.searchCriteriaFulfillingVideos, id: \.index) { video in
                                    VStack(alignment: .leading) {
                                        Text(video.name ?? "Progress Video [\(video.index)]")
                                            .font(.title3)
                                            .bold()
                                            .lineLimit(1)
                                        
                                        HStack(alignment: .top) {
                                            if let date = video.creationDate {
                                                Text(viewModel.videoDateFormatter.string(from: date))
                                                    .font(.caption)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("Duration: \(viewModel.videoDurationFormatter.string(from: video.length) ?? "00:00")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack {
                                            self.progressImage(from: video.firstImage, isLarge: true)
                                            
                                            ForEach(0..<3, id: \.self) { index in
                                                Spacer()
                                                
                                                self.progressImage(from: video.middleImages[index], isLarge: false)
                                            }
                                            
                                            Spacer()
                                            
                                            self.progressImage(from: video.lastImage, isLarge: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .searchable(text: $viewModel.searchText)
                    .refreshable {
                        viewModel.loadProgressVideos()
                    }
                } else {
                    ProgressView()
                    Text("Loading videos...")
                }
            }
            .searchable(text: $viewModel.searchText)
            .navigationTitle("Progress Videos")
        }
    }
    
    private func progressImage(from uiImage: UIImage?, isLarge: Bool) -> some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                Image(uiImage: uiImage ?? .init(systemName: "photo")!)
                    .resizable()
                    .scaledToFill()
            }
            .cornerRadius(4)
            .clipped()
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
            .frame(maxWidth: isLarge ? Self.largeProgressImageSize : Self.smallProgressImageSize,
                   maxHeight: isLarge ? Self.largeProgressImageSize: Self.smallProgressImageSize)
    }
}

struct ProgressVideosCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressVideosCollectionView()
    }
}
