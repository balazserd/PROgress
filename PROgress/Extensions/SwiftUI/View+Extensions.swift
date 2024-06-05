//
//  View+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 02/06/2024.
//

import Foundation
import SwiftUI

extension View {
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
