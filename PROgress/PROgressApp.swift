//
//  PROgressApp.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI
import SwiftData
import TipKit
import os

@main
struct PROgressApp: App {
    static let groupIdentifier = "group.com.ebuniapps.PROgress"

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environmentObject(GlobalSettings.shared)
        }
    }
    
    init() {
        do {
            #if DEBUG
            try Tips.resetDatastore()
            #endif
            
            try Tips.configure()
        } catch let error {
            PRLogger.app.error("Tips could not be configured: [\(error)]")
        }
    }
}

struct MainWindow: View {
    @State private var selection: Tab = .newVideo
    
    var body: some View {
        TabView(selection: $selection) {
            ProgressVideosCollectionView()
                .tabItem {
                    Label("Videos", systemImage: "photo.stack")
                }
                .tag(Tab.videos)
            
            NewProgressVideoView()
                .tabItem {
                    Label("New", systemImage: "plus.square")
                }
                .tag(Tab.newVideo)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.2")
                }
                .tag(Tab.settings)
        }
    }
    
    private enum Tab: Int {
        case videos
        case newVideo
        case settings
    }
}
