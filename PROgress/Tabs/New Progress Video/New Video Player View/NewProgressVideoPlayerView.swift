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
    
    @State private var showShareSheet = false
    
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
        .padding(.vertical)
        .navigationTitle(video.name)
        .shareView(with: [video.url], isPresented: $showShareSheet)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            switch viewModel.saveStatus {
            case .inProgress:
                ProgressView()
                    .transition(.opacity)
                
            case .finished:
                Button(action: {}) {
                    Image(systemName: "arrow.down.circle")
                        .overlay(alignment: .topTrailing) {
                            ZStack {
                                Circle().foregroundStyle(.white)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .scaleEffect(of: 0.75)
                            .offset(x: 10, y: -8)
                        }
                }
                .disabled(true)
                .transition(.opacity)
                
            case .none:
                Button(action: { viewModel.saveVideo(video) }) {
                    Image(systemName: "arrow.down.circle")
                }
                .transition(.opacity)
                
            default:
                EmptyView()
                    .transition(.opacity)
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: { showShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
            }
            .padding(.top, -3)
        }
    }
}

struct NewProgressVideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProgressVideoPlayerView(video:
                ProgressVideo(videoId: UUID(),
                              url: URL(string: FileManager().currentDirectoryPath)!,
                              resolution: CGSize(width: 640, height: 2560))
            )
        }
    }
}
