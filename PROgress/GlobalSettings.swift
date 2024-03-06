//
//  GlobalSettings.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation

class GlobalSettings: ObservableObject {
    var subscriptionType: SubscriptionType = .premium
    
    // MARK: - Convenience computed variables
    var isPremiumUser: Bool { self.subscriptionType == .premium }
}

enum SubscriptionType {
    case free
    case premium
}
