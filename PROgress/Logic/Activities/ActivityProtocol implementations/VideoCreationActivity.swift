//
//  VideoCreationActivity.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 24..
//

import Foundation

extension ActivityProtocol where Self == VideoCreationActivity {
    static func videoCreation(_ attributes: VideoCreationLiveActivityAttributes) -> Self {
        return VideoCreationActivity(attributes: attributes)
    }
}

actor VideoCreationActivity: ActivityProtocol {
    let attributes: VideoCreationLiveActivityAttributes
    
    let initialState = VideoCreationLiveActivityAttributes.ContentState.inProgress(value: 0.0)
    
    var id: String!
    
    init(attributes: VideoCreationLiveActivityAttributes) {
        self.attributes = attributes
    }
    
    func staleDate() -> Date {
        Calendar.current.date(byAdding: .minute, value: 20, to: Date())!
    }
    
    func onDismissed() {
        PRLogger.activities.debug("Activity was dismissed!")
        
        let imageUrls = [attributes.firstImage] + attributes.middleImages + [attributes.lastImage]
        
        Task.detached {
            imageUrls
                .compactMap { $0 }
                .forEach { imageUrl in
                    do {
                        try FileManager.default.removeItem(at: imageUrl)
                        PRLogger.activities.debug("Successfully deleted Live Activity asset.")
                    } catch let error {
                        PRLogger.activities.error("Could not delete temporary Live Activity asset! [\(error)]")
                    }
                }
        }
    }
}
