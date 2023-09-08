//
//  SettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(.privateActivitiesMode) private var privateActivitiesMode: Bool = false
    
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
                
                Section("Subscription") {
                    HStack {
                        Text("Current plan")
                        Spacer()
                        Text("Free")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Upgrade", action: {
                        // TODO
                    })
                    
                    Button(role: .destructive) {
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
                    
                    Button {
                        // TODO
                    } label: {
                        Text("Report an issue")
                    }
                }
            }
            .navigationTitle("Settings")
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
