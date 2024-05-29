//
//  SettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import SwiftUI
import os
import StoreKit

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    @AppStorage(.privateActivitiesMode) private var privateActivitiesMode: Bool = false
    
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    @State private var isShowingSubscriptionsSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activities, Notifications") {
                    VStack(alignment: .leading) {
                        Toggle("Private Activities Mode", isOn: $privateActivitiesMode)
                        
                        Text("When turned on, activities on the Lock Screen and in the Dynamic Island / Notification Status Bar will not contain images, just the progress status.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Feedback") {
                    Button {
                        guard let reviewUrl = URL(string: "https://apps.apple.com/app/id<my-app-store-id>?action=write-review") else {
                            PRLogger.app.error("Could not construct App Store App Review URL!")
                            return
                        }
                        
                        openURL(reviewUrl)
                    } label: {
                        Text("Write a Review")
                    }
                    
                    Button(role: .destructive) {
                        // TODO
                    } label: {
                        Text("Report an issue")
                    }
                }
                
                Section("Subscription") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current plan")
                            Spacer()
                            Text(globalSettings.subscriptionType.rawValue)
                                .foregroundColor(.secondary)
                        }
                        
                        if globalSettings.subscriptionType == .premium {
                            VStack(alignment: .leading, spacing: 8) {
                                if let expirationDate = globalSettings.subscriptionTransaction?.expirationDate {
                                    Text("Your current Premium plan billing period lasts until\n")
                                    +
                                    Text("\(DateFormatter.videoDateFormatter.string(from: expirationDate)).")
                                        .bold()
                                    
                                    Text("This does not mean you have no other subscriptions coming up after the above shown date. Check your Apple ID settings in the Settings app for your full list of subscriptions related to PROgress.")
                                    
                                    Text("Auto-renewable subscriptions can be cancelled anytime and they will last until the end of the current billing period.")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Button("Change subscription", action: {
                        self.isShowingSubscriptionsSheet = true
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
                
                Section("Miscellaneous") {
                    NavigationLink(value: SubPages.licenseAttribution) {
                        Text("License Attribution")
                    }
                    
                    Button {
                        // TODO
                    } label: {
                        Text("Privacy Policy")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isShowingSubscriptionsSheet) {
                PremiumSubscriptionView()
            }
            .navigationDestination(for: SubPages.self) {
                switch $0 {
                case .licenseAttribution:
                    EmptyView()
                }
            }
        }
    }
    
    private enum SubPages {
        case licenseAttribution
    }
}
