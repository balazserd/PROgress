//
//  VideoCreationLiveActivityAttributes.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation
import ActivityKit

struct VideoCreationLiveActivityAttributes: Equatable, ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
        var description: String
        
        static func inProgress(value: Double) -> Self {
            .init(progress: value, description: "Creating your video...")
        }
        
        static func ended() -> Self {
            .init(progress: 1.0, description: "Your video is ready!")
        }
    }

    // Fixed non-changing properties about your activity go here!
    var firstImage: URL?
    var middleImages: [URL?]
    var lastImage: URL?
}
