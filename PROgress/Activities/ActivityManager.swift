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
    func startActivity<A: ActivityProtocol>(_ activity: A) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw ActivityManagementError.activitiesAreDisabled
        }
        
        let activityInitialContent = ActivityContent(state: activity.initialState, staleDate: activity.staleDate())
        let activityKitActivity = try Activity.request(attributes: activity.attributes, content: activityInitialContent)
        
        activity.id = activityKitActivity.id
        
        activity.onStart()
    }
    
    func updateActivity<A: ActivityProtocol>(_ activity: A,
                                             with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(activity.id, withAttributeType: A.Attributes.self)
        
        let newActivityContent = ActivityContent(state: state, staleDate: activity.staleDate())
        await activityKitActivity.update(newActivityContent)
    }
    
    func endActivity<A: ActivityProtocol>(_ activity: A,
                                          with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(activity.id, withAttributeType: A.Attributes.self)
        
        let finalActivityContent = ActivityContent(state: state, staleDate: activity.staleDate())
        await activityKitActivity.end(finalActivityContent)
        
        activity.onFinish()
    }
    
    private func activityWithId<Attributes: ActivityAttributes>(_ id: String,
                                                                withAttributeType attributeType: Attributes.Type) throws -> Activity<Attributes> {
        guard let activityKitActivity = Activity<Attributes>.activities.first(where: { $0.id == id }) else {
            throw ActivityManagementError.activityNotFound
        }
        
        return activityKitActivity
    }
}

enum ActivityManagementError: Error {
    case activitiesAreDisabled
    case activityNotFound
}
