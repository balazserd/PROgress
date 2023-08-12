//
//  NewProgressVideoPlayerView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

import SwiftUI
import AVKit

struct NewProgressVideoPlayerView: View {
    var video: ProgressVideo
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: video.url))
    }
}

struct NewProgressVideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoPlayerView(video: ProgressVideo(url: .init(string: "")!))
    }
}
