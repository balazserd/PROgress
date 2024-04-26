//
//  ModelContainer+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 23/04/2024.
//

import Foundation
import SwiftData

extension ModelContainer {
    func makeNewContext() -> ModelContext {
        ModelContext(self)
    }
    
    func withNewContext(_ block: (ModelContext) throws -> Void) rethrows {
        let context = ModelContext(self)
        context.autosaveEnabled = true
        
        try block(context)
    }
}
