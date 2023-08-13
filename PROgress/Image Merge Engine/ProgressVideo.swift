//
//  ProgressVideo.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 09..
//

import Foundation

struct ProgressVideo: Hashable {
    var videoId: UUID
    var url: URL
    var resolution: CGSize
    var name: String = "Progress Video"
    
    func hash(into hasher: inout Hasher) {
        videoId.hash(into: &hasher)
    }
}
