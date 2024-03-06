//
//  AVAssetWriterInput+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import AVFoundation

extension AVAssetWriterInput {
    // note: the solution to KVO isReadyForMediaData in as an async sequence did not work 
    func waitUntilReadyForMoreMediaData() async throws {
        while !self.isReadyForMoreMediaData {
            PRLogger.imageProcessing.debug("Not ready for more media data! Waiting...")
            try await Task.sleep(for: .milliseconds(200))
        }
    }
}
