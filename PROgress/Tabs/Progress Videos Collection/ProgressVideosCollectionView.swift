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
    
    var body: some View {
        NavigationStack {
            VStack {
                if let videos = viewModel.videos {
                    List {
                        ForEach(videos, id: \.index) { video in
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
                                    Rectangle()
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay {
                                            Image(uiImage: video.firstImage)
                                                .resizable()
                                                .scaledToFill()
                                        }
                                        .cornerRadius(4)
                                        .clipped()
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                                        .frame(maxWidth: Self.largeProgressImageSize,
                                               maxHeight: Self.largeProgressImageSize)
                                    
                                    Spacer()
                                    
                                    Rectangle()
                                        .aspectRatio(1, contentMode: .fill)
                                        .overlay {
                                            Image(uiImage: video.lastImage)
                                                .resizable()
                                                .scaledToFill()
                                        }
                                        .cornerRadius(4)
                                        .clipped()
                                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                                        .frame(maxWidth: Self.largeProgressImageSize,
                                               maxHeight: Self.largeProgressImageSize)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                    Text("Loading videos...")
                }
            }
            .navigationTitle("Progress Videos")
            .onAppear {
                viewModel.loadProgressVideos()
            }
        }
    }
}

struct ProgressVideosCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressVideosCollectionView()
    }
}
