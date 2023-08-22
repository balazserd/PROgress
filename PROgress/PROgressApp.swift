//
//  PROgressApp.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI

@main
struct PROgressApp: App {
    static let groupIdentifier = "group.com.ebuniapps.PROgress"
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainWindow()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
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
        }
    }
}
