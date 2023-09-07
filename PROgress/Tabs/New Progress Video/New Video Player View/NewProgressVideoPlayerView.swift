//
//  NewProgressVideoPlayerView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

import SwiftUI
import EBUniAppsKit
import AVKit
import Combine

struct NewProgressVideoPlayerView: View {
    @StateObject private var viewModel = NewProgressVideoPlayerViewModel()
    
    var video: ProgressVideo
    private let avPlayer: AVPlayer
    
    init(video: ProgressVideo) {
        self.video = video
        self.avPlayer = AVPlayer(url: video.url)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            AVPlayerViewController.Representable(player: avPlayer)
                .aspectRatio(video.resolution.width / video.resolution.height, contentMode: .fit)
                .padding(.horizontal)
                .shadow(radius: 15)
                .onAppear {
                    avPlayer.play()
                }
                .toolbar { toolbar }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You can save the video into your Photos app with the \(Image(systemName: "arrow.down.circle")) button.")
                
                Text("You can also share the video via compatible apps with the \(Image(systemName: "square.and.arrow.up")) button.")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
        .navigationTitle(video.name)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { viewModel.saveVideo(video) }) {
                Image(systemName: "arrow.down.circle")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: { /* viewModel.share() */ }) {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}

struct NewProgressVideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProgressVideoPlayerView(video:
                ProgressVideo(videoId: UUID(),
                              url: URL(string: FileManager().currentDirectoryPath)!,
                              resolution: CGSize(width: 640, height: 640))
            )
        }
    }
}
