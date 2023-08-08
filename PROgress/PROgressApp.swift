//
//  PROgressApp.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI

@main
struct PROgressApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NewProgressVideoView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
