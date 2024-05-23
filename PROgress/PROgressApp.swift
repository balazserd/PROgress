//
//  PROgressApp.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI
import SwiftData

@main
struct PROgressApp: App {
    static let groupIdentifier = "group.com.ebuniapps.PROgress"

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(GlobalSettings.shared)
        }
    }
}

struct MainWindow: View {
    var body: some View {
        TabView {
            ProgressVideosCollectionView()
                .tabItem {
                    Label("Videos", systemImage: "photo.stack")
                }
            
            NewProgressVideoView()
                .tabItem {
                    Label("New", systemImage: "plus.square")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.2")
                }
        }
    }
}
