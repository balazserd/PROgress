//
//  ActivityManager.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation
import ActivityKit

class ActivityManager {
    /// Starts a Live Activity for this activity.
    ///
    /// This method will set the ``ActivityProtocol/id`` property.
    func startActivity<A: ActivityProtocol>(_ activity: A) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw ActivityManagementError.activitiesAreDisabled
        }
        
        let activityInitialContent = ActivityContent(state: activity.initialState, staleDate: activity.staleDate())
        let activityKitActivity = try Activity.request(attributes: activity.attributes, content: activityInitialContent)
        
        activity.id = activityKitActivity.id
    }
    
    func updateActivity<A: ActivityProtocol>(_ activity: A, with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(activity.id, withAttributeType: A.Attributes.self)
        
        let newActivityContent = ActivityContent(state: state, staleDate: activity.staleDate())
        await activityKitActivity.update(newActivityContent)
    }
    
    func endActivity<A: ActivityProtocol>(_ activity: A, with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(activity.id, withAttributeType: A.Attributes.self)
        
        let finalActivityContent = ActivityContent(state: state, staleDate: activity.staleDate())
        await activityKitActivity.end(finalActivityContent)
    }
    
    private func activityWithId<ATTR>(_ id: String, withAttributeType attributeType: ATTR.Type) throws -> Activity<ATTR>
    where ATTR: ActivityAttributes {
        guard let activityKitActivity = Activity<ATTR>.activities.first(where: { $0.id == id }) else {
            throw ActivityManagementError.activityNotFound
        }
        
        return activityKitActivity
    }
}

enum ActivityManagementError: Error {
    case activitiesAreDisabled
    case activityNotFound
}

protocol ActivityProtocol: AnyObject {
    associatedtype Attributes: ActivityAttributes
    
    var attributes: Attributes { get }
    var initialState: Attributes.ContentState { get }
    var id: String! { get set }
    
    func staleDate() -> Date
}

extension ActivityProtocol where Self == VideoCreationActivity {
    static func videoCreation(_ attributes: VideoCreationLiveActivityAttributes) -> Self {
        return VideoCreationActivity(attributes: attributes)
    }
}

class VideoCreationActivity: ActivityProtocol {
    var attributes: VideoCreationLiveActivityAttributes
    
    let initialState = VideoCreationLiveActivityAttributes.ContentState.inProgress(value: 0.0)
    
    var id: String!
    
    init(attributes: VideoCreationLiveActivityAttributes) {
        self.attributes = attributes
    }
    
    func staleDate() -> Date {
        Calendar.current.date(byAdding: .minute, value: 20, to: Date())!
    }
}
