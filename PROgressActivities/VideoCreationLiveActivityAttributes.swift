//
//  VideoCreationLiveActivityAttributes.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation
import ActivityKit

struct VideoCreationLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
    }

    // Fixed non-changing properties about your activity go here!
    var firstImage: URL?
    var middleImages: [URL?]
    var lastImage: URL?
    var title: String
}
