//
//  PremiumSubscriptionView+Tips.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/07/2024.
//

import Foundation
import TipKit

struct SubscriptionSelectionTip: Tip {
    @Parameter static var isShowing: Bool = false
    var rules: [Rule] {
        [#Rule(Self.$isShowing) { $0 }]
    }
    
    var title: Text {
        Text("Subscription durations")
    }
    
    var message: Text? {
        Text("If you plan to use the premium features **regularly** (like creating a progress video of something on a weekly basis) you can save money by opting for a yearly subscription.")
            .font(.caption2)
    }
    
    var image: Image? {
        Image(systemName: "questionmark.circle")
    }
}
