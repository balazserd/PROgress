//
//  AVAssetWriterInput+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import AVFoundation

extension AVAssetWriterInput {
    func waitUntilReadyForMoreMediaData() async {
        if self.isReadyForMoreMediaData {
            return
        }
        
        PRLogger.imageProcessing.debug("Not ready for more media data! Waiting...")
        
        let readinessChanged = self.publisher(for: \.isReadyForMoreMediaData,
                                              options: [.initial, .new])
        
        for await ready in readinessChanged.values {
            guard ready else { continue }
            
            PRLogger.imageProcessing.debug("Became ready for more media data.")
            
            return
        }
    }
}
