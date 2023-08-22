//
//  ActivityManager.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation
import ActivityKit

class ActivityManager {
    func startActivity<A: ActivityProtocol>(_ activity: A) throws -> Activity<A.Attributes> {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw ActivityManagementError.activitiesAreDisabled
        }
        
        let activityInitialContent = ActivityContent(state: activity.initialState, staleDate: activity.staleDate)
        return try Activity.request(attributes: activity.attributes, content: activityInitialContent)
    }
    
    func updateActivity<ATTR: ActivityAttributes, ACT: Activity<ATTR>>(_ activity: ACT, with state: ATTR.ContentState) throws {
        
    }
}

enum ActivityManagementError: Error {
    case activitiesAreDisabled
}

protocol ActivityProtocol {
    associatedtype Attributes: ActivityAttributes
    
    var attributes: Attributes { get }
    var staleDate: Date { get }
    var initialState: Attributes.ContentState { get }
}

extension ActivityProtocol where Self == VideoCreationActivity {
    static func videoCreation(_ attributes: VideoCreationLiveActivityAttributes) -> Self {
        return VideoCreationActivity(attributes: attributes)
    }
}

struct VideoCreationActivity: ActivityProtocol {
    var attributes: VideoCreationLiveActivityAttributes
    let staleDate = Calendar.current.date(byAdding: .minute, value: 20, to: Date())!
    let initialState = VideoCreationLiveActivityAttributes.ContentState(progress: 0.0)
}
