//
//  SettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import SwiftUI
import os

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
                    HStack {
                        Text("Current plan")
                        Spacer()
                        Text(globalSettings.subscriptionType.rawValue)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Upgrade", action: {
                        self.isShowingSubscriptionsSheet = true
                    })
                    
                    Button {
                        // TODO
                    } label: {
                        Text("Restore purchase")
                    }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
