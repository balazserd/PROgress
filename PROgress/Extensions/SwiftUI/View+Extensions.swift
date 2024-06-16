//
//  View+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 02/06/2024.
//

import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension View {
    func subscriptionSheetLink(isPresented: Binding<Bool>) -> some View {
        self
            .sheet(isPresented: isPresented) {
                PremiumSubscriptionView()
            }
            .environment(\.openURL, OpenURLAction { url in
                PRLogger.app.debug("Handling URL on PremiumVideoSettingsSection page.")
                
                if url == URL.openSubscriptionSheet {
                    isPresented.wrappedValue = true
                }
                
                return .discarded
            })
    }
}
