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
                let player = AVPlayer(url: urlAsset.url)
                
                AVPlayerViewController.Representable(player: player)
                    .padding(20)
                    .shadow(radius: 15)
                    .onAppear {
                        player.play()
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
