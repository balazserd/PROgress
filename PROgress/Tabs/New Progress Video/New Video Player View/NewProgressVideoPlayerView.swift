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
    @StateObject private var viewModel: NewProgressVideoPlayerViewModel
    private var video: ProgressVideo { self.viewModel.video }
    
    @State private var showShareSheet = false
    @State private var isShowingVideoNameEditor: Bool = false
    
    private let avPlayer: AVPlayer
    
    init(video: ProgressVideo) {
        self._viewModel = StateObject(wrappedValue: .init(video: video))
        self.avPlayer = AVPlayer(url: video.url)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            AVPlayerViewController.Representable(player: avPlayer)
                .aspectRatio(viewModel.video.resolution.width / viewModel.video.resolution.height, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 20)
                .layoutPriority(.infinity)
                .onAppear {
                    avPlayer.play()
                }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You can save the video into your Photos app with the \(Image(systemName: "arrow.down.circle")) button.")
                
                Text("You can also share the video via compatible apps with the \(Image(systemName: "square.and.arrow.up")) button.")
            }
            .font(.system(size: 10))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(20)
        .toolbar { toolbar }
        .navigationTitle(viewModel.video.name)
        .shareView(with: [viewModel.video.url], isPresented: $showShareSheet)
        .videoNameEditorAlert($viewModel.video.name, isPresented: $isShowingVideoNameEditor)
        .ignoresSafeArea(.keyboard)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: { isShowingVideoNameEditor = true }) {
                Image(systemName: "pencil")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            switch viewModel.saveStatus {
            case .inProgress:
                ProgressView()
                    .transition(.opacity)
                
            case .none where viewModel.video.persistentIdentifier != nil,
                 .finished:
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
                
            case .none where viewModel.video.persistentIdentifier == nil:
                Button(action: { viewModel.saveVideo() }) {
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
                              resolution: CGSize(width: 2560, height: 2560))
            )
        }
    }
}
