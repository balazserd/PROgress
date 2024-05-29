//
//  Transaction+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/05/2024.
//

import Foundation
import StoreKit

extension Transaction {
    var expired: Bool {
        self.expirationDate ?? .distantFuture < Date()
    }
}
