//
//  ActivityManager.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 22..
//

import Foundation
import ActivityKit

final class ActivityManager: Sendable {
    /// Starts a Live Activity for this activity.
    ///
    /// This method will set the ``ActivityProtocol/id`` property.
    func startActivity<A: ActivityProtocol>(_ activity: A) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw ActivityManagementError.activitiesAreDisabled
        }
        
        let initialActivityContent = ActivityContent(state: await activity.initialState, staleDate: await activity.staleDate())
        do {
            let activityKitActivity = try Activity.request(attributes: await activity.attributes, content: initialActivityContent)
            
            await activity.setId(to: activityKitActivity.id)
            await activity.onStart()
            
            /// Listen for dismiss event.
            Task.detached(priority: .background) { [id = activityKitActivity.id] in
                let _act = try self.activityWithId(id, withAttributeType: A.Attributes.self)
                
                for await stateUpdate in _act.activityStateUpdates {
                    guard stateUpdate == .dismissed else { continue }
                    
                    await activity.onDismissed()
                    break
                }
            }
        } catch let error {
            PRLogger.activities.error("Activity could not be started! \(error)")
            throw error
        }
    }
    
    func updateActivity<A: ActivityProtocol>(_ activity: A,
                                             with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(await activity.id, withAttributeType: A.Attributes.self)
        
        let newActivityContent = ActivityContent(state: state, staleDate: await activity.staleDate())
        await activityKitActivity.update(newActivityContent)
    }
    
    func endActivity<A: ActivityProtocol>(_ activity: A,
                                          with state: A.Attributes.ContentState) async throws {
        let activityKitActivity = try self.activityWithId(await activity.id, withAttributeType: A.Attributes.self)
        
        let finalActivityContent = ActivityContent(state: state, staleDate: await activity.staleDate())
        await activityKitActivity.end(finalActivityContent)
        
        await activity.onEnded()
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
