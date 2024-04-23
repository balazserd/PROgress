//
//  ActivityProtocol.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 24..
//

import Foundation
import ActivityKit

protocol ActivityProtocol: Actor {
    associatedtype Attributes: ActivityAttributes, Sendable where Attributes.ContentState: Sendable
    
    var attributes: Attributes { get }
    var initialState: Attributes.ContentState { get }
    var id: String! { get set }
    
    func staleDate() -> Date
    
    func setId(to id: String)
    func onStart()
    func onEnded()
    func onDismissed()
}

extension ActivityProtocol {
    func onStart() { }
    func onEnded() { }
    func onDismissed() { }
    
    func setId(to id: String) {
        self.id = id
    }
}
