//
//  Text+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/03/2024.
//

import Foundation
import SwiftUI

extension Text {
    func tableRowDataStyle() -> some View {
        self.font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
    
    func subscriptionSheetLink(isPresented: Binding<Bool>) -> some View {
        self
            .sheet(isPresented: isPresented) {
                PremiumSubscriptionView()
            }
            .environment(\.openURL, OpenURLAction { url in
                PRLogger.app.debug("Handling URL on PremiumVideoSettingsSection page.")
                
                if url.absoluteString == "PROgress://open-subscriptions-sheet" {
                    isPresented.wrappedValue = true
                }
                
                return .discarded
            })
    }
}
