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
            Text("This page is dedicated to giving credit to public resources which helped making this app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Section("Used Libraries") {
                externalLink(name: "Factory", url: .factory)
            }
            
            Section("Additional Tools") {
                externalLink(name: "Pixabay", url: .pixabay)
                externalLink(name: "AppMockUp Studio", url: .appMockupStudio)
            }
        }
        .navigationTitle("License Attribution")
    }
    
    @ViewBuilder
    private func externalLink(name: String, url: URL) -> some View {
        Link(destination: url, label: {
            HStack {
                Text(name)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
            }
        })
    }
}

#Preview {
    NavigationStack {
        LicenseAttributionPage()
    }
}
