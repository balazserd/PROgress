//
//  LicenseAttributionPage.swift
//  PROgress
//
//  Created by Balázs Erdész on 24/06/2024.
//

import SwiftUI

struct LicenseAttributionPage: View {
    var body: some View {
        Form {
            Section {
                Text("This page is dedicated to giving credit to public resources which helped making this app.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section("Used Libraries") {
                Link(destination: .factory, label: {
                    HStack {
                        Text("Factory")
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right")
                    }
                })
            }
        }
        .navigationTitle("License Attribution")
    }
}

#Preview {
    NavigationStack {
        LicenseAttributionPage()
    }
}
