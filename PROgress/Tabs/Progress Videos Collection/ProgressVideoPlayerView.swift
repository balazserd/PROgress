//
//  ProgressVideoPlayerView.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import SwiftUI
import AVFoundation
import AVKit

struct ProgressVideoPlayerView: View {
    @Bindable private var viewModel: ProgressVideoPlayerViewModel
    
    @State private var showShareSheet = false
    
    @MainActor
    init(video: VideoAsset) {
        self._viewModel = .init(ProgressVideoPlayerViewModel(videoAsset: video))
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if viewModel.avAsset != nil {
                if let size = viewModel.assetAspectRatio, let player = viewModel.player {
                    AVPlayerViewController.Representable(player: player)
                        .aspectRatio(size, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding([.top, .horizontal], 20)
                        .shadow(radius: 15)
                        .layoutPriority(.infinity)
                        .onAppear {
                            player.play()
                        }
                    
                    VStack(alignment: .leading) {
                        Text("Info")
                            .font(.subheadline)
                        
                        Divider()
                        
                        ScrollView {
                            HStack {
                                Text("Duration")
                                    .bold()
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(DateComponentsFormatter.videoDurationFormatter.string(from: .init(second: Int(viewModel.videoAsset.length))) ?? "00:00")
                                    .font(.caption)
                            }
                            
                            HStack {
                                Text("Created")
                                    .bold()
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text(DateFormatter.videoDateFormatter.string(from: viewModel.videoAsset.creationDate ?? Date()))
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(20)
                    .frame(minHeight: 150)
                } else {
                    ContentUnavailableView("Failed to load video",
                                           systemImage: "exclamationmark.triangle.fill",
                                           description: Text("Please check that the video exists in the 'PROgress' dedicated folder in the Photos app, then try again."))
                    .symbolRenderingMode(.multicolor)
                }
            } else {
                ProgressView()
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationTitle($viewModel.videoAsset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { self.toolbar }
        .shareView(with: [viewModel.avAsset?.url as Any], isPresented: $showShareSheet)
    }
    
    @ToolbarContentBuilder @MainActor
    private var toolbar: some ToolbarContent {
        if viewModel.avAsset != nil {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showShareSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    ContentUnavailableView("Failed to load video",
                           systemImage: "exclamationmark.triangle.fill",
                           description: Text("Please check that the video exists in the 'PROgress' dedicated folder in the Photos app, then try again."))
        .symbolRenderingMode(.multicolor)
}
