//
//  PremiumVideoSettingsSection.swift
//  PROgress
//
//  Created by Balázs Erdész on 15/04/2024.
//

import SwiftUI
import os

struct PremiumVideoSettingsSection: View {
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    @State private var isShowingSubscriptionsSheet: Bool = false
    
    var body: some View {
        Section {
            Toggle(isOn: $viewModel.userSettings.hideLogo) {
                Text("Hide PROgress logo")
                    .foregroundColor(globalSettings.isPremiumUser ? .primary : .secondary)
            }
            .disabled(!globalSettings.isPremiumUser)
            
            VStack(alignment: .leading) {
                Toggle(isOn: $viewModel.userSettings.addBeforeAfterFinalImage) {
                    Text("Add before-after image as last frame")
                }
                
                Text("A final frame is appended to the video that shows the first and the last photo side-by-side.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(globalSettings.isPremiumUser ? .primary : .secondary)
            .disabled(!globalSettings.isPremiumUser)
        } header: {
            Text("Premium")
        } footer: {
            if !globalSettings.isPremiumUser {
                Text(onlyWithPremiumAttributedString)
                    .font(.caption)
                    .subscriptionSheetLink(isPresented: $isShowingSubscriptionsSheet)
            }
        }
    }
    
    private let onlyWithPremiumAttributedString: AttributedString = {
        let regularTextPart = AttributedString("These options are only available with PROgress Premium subscription. ")
        var linkPart = AttributedString("More info...")
        linkPart.link = .openSubscriptionSheet
        
        return regularTextPart + linkPart
    }()
}
