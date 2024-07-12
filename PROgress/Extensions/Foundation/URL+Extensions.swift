//
//  URL+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 15/06/2024.
//

import Foundation

extension URL {
    static let openSubscriptionSheet = URL(string: "PROgress://open-subscriptions-sheet")!
    
    static let eula = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let review = URL(string: "https://apps.apple.com/app/id6503061802?action=write-review")!
    static let privacyPolicy = URL(string: "https://balazserd.github.io/PROgress/Privacy_Policy.html")!
    
    // MARK: - License Attribution
    static let factory = URL(string: "https://github.com/hmlongco/Factory")!
}
