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
            if let urlAsset = viewModel.avAsset {
                if let size = viewModel.assetAspectRatio {
                    let player = AVPlayer(url: urlAsset.url)
                    
                    AVPlayerViewController.Representable(player: player)
                        .shadow(radius: 15)
                        .aspectRatio(size, contentMode: .fit)
                        .padding(20)
                        .onAppear {
                            player.play()
                        }
                    
                    Spacer()
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
        .navigationTitle(viewModel.videoAsset.name ?? "[Unnamed Progress Video]")
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
                .padding(.top, -3)
            }
        }
    }
}

#Preview {
    ContentUnavailableView("Failed to load video",
                           systemImage: "exclamationmark.triangle.fill",
                           description: Text("Please check that the video exists in the 'PROgress' dedicated folder in the Photos app try again."))
        .symbolRenderingMode(.multicolor)
}
