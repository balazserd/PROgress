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
}
