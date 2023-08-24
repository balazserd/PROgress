//
//  ActivityProtocol.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 24..
//

import Foundation
import ActivityKit

protocol ActivityProtocol: AnyObject {
    associatedtype Attributes: ActivityAttributes
    
    var attributes: Attributes { get }
    var initialState: Attributes.ContentState { get }
    var id: String! { get set }
    
    func staleDate() -> Date
    
    func onStart()
    func onFinish()
}

extension ActivityProtocol {
    func onStart() { }
    func onFinish() { }
}
