//
//  SettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import SwiftUI
import os
import StoreKit
import MessageUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    @AppStorage(.privateActivitiesMode, store: .appGroup) private var privateActivitiesMode: Bool = false
    
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showManageSubscriptionsSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                
                subscriptionSection
                
                feedbackSection
                
                miscellaneousSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $viewModel.isShowingSubscriptionsSheet) {
                PremiumSubscriptionView()
            }
            .navigationDestination(for: SubPages.self) {
                switch $0 {
                case .licenseAttribution:
                    LicenseAttributionPage()
                }
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section("Activities, Notifications") {
            VStack(alignment: .leading) {
                Toggle("Private Activities Mode", isOn: $privateActivitiesMode)
                
                Text("When turned on, activities on the Lock Screen and in the Dynamic Island / Notification Status Bar will not contain images, just the progress status.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Subscription Section
    private var subscriptionSection: some View {
        Section("Subscription") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Current plan")
                    Spacer()
                    Text(globalSettings.subscriptionType.typeDescription)
                        .foregroundColor(.secondary)
                }
                
                if globalSettings.isPremiumUser {
                    VStack(alignment: .leading, spacing: 8) {
                        if globalSettings.subscriptionType < .premium_lifetime {
                            Text("You receive Premium features via a renewing subscription. Check the subscription details via the \"Manage subscriptions\" menu item or, alternatively, modify your subscription type via the **Upgrade subscription** menu item.")
                            
                            Text("Auto-renewable subscriptions can be cancelled anytime and they will last until the end of the current billing period.")
                        } else {
                            Text("You have purchased a **Lifetime Premium** plan. You can continue to use the Premium features as long as the application is available.")
                            
                            Text("If you upgraded to lifetime from a recurring billing plan, make sure to cancel that plan.")
                                .bold()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                }
            }
            
            if globalSettings.isPremiumUser && globalSettings.subscriptionType < .premium_lifetime {
                Button("Upgrade subscription") {
                    viewModel.isShowingSubscriptionsSheet = true
                }
            }
            
            Button("Manage subscriptions", action: {
                showManageSubscriptionsSheet = true
            })
            
            Button {
                globalSettings.requestPurchaseRestore()
            } label: {
                HStack {
                    Text("Restore purchase")
                    
                    if globalSettings.purchaseRestorationInProgress {
                        Spacer()
                        
                        ProgressView()
                    }
                }
            }
            .disabled(globalSettings.purchaseRestorationInProgress)
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptionsSheet)
    }
    
    // MARK: - Feedback Section
    private var feedbackSection: some View {
        Section("Feedback") {
            Button {
                openURL(.review)
            } label: {
                Text("Write a Review")
            }
            
            Button(role: .destructive) {
                viewModel.isShowingIssueReportMailSheet = true
            } label: {
                HStack {
                    Text("Report an issue")
                    Spacer()
                    Image(systemName: "envelope")
                }
            }
            .sheet(isPresented: $viewModel.isShowingIssueReportMailSheet) {
                SupportEmailView(mailComposeResult: $viewModel.issueReportMailCompositionResult)
                    .alert("Status update", 
                           isPresented: $viewModel.isShowingIssueReportMailCompositionAlert) {
                        Button("OK") {
                            viewModel.isShowingIssueReportMailCompositionAlert = false
                            viewModel.isShowingIssueReportMailSheet = false
                        }
                    } message: {
                        Text(viewModel.issueReportMailCompositionAlertMessage ?? "[no message]")
                    }
            }
        }
    }
    
    // MARK: - Miscellaneous Section
    private var miscellaneousSection: some View {
        Section("Miscellaneous") {
            Button(action: { openURL(.eula) }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("End User License Agreement")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    
                    Text("Important: You accepted this license agreement when you downloaded this application.")
                        .font(.caption)
                        .tint(.gray)
                }
            }
            
            Link(destination: .privacyPolicy, label: {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
            })
            
            NavigationLink(value: SubPages.licenseAttribution) {
                Text("License Attribution")
            }
        }
    }
    
    // MARK: - Navigation
    private enum SubPages {
        case licenseAttribution
    }
}

#Preview {
    VStack {
        SettingsView()
    }
    .environmentObject(GlobalSettings.shared)
}
