//
//  GlobalSettings.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation
import StoreKit
import os
import Combine

@MainActor
class GlobalSettings: ObservableObject {
    @Published var subscriptionType: SubscriptionType = .free
    var isPremiumUser: Bool { self.subscriptionType == .premium }
    
    // MARK: - Initializer
    static let shared = GlobalSettings()
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Private operations
    private nonisolated func setupSubscriptions() {
        Task(priority: .background) {
            await self.refreshPurchaseStates()
            
            for await notification in NotificationCenter.default.notifications(named: .didPurchaseItem) {
                await self.refreshPurchaseStates()
            }
        }
        
        Task(priority: .background) {
            for await update in Transaction.updates {
                PRLogger.purchases.debug("Received update to a transaction. Refreshing purchase states...")
                await self.refreshPurchaseStates()
            }
        }
    }
    
    private func refreshPurchaseStates() async {
        PRLogger.purchases.debug("Will refresh subscription states.")
        
        for await verificationResult in Transaction.currentEntitlements {
            assertTransactionVerificationResult(verificationResult)
        }
    }
    
    private func assertTransactionVerificationResult(_ verificationResult: VerificationResult<Transaction>) {
        switch verificationResult {
        case .verified(let transaction):
            PRLogger.purchases.debug("Received verified transaction with id [\(transaction.id)] for product [\(transaction.productID, privacy: .public)].")
            guard let group = transaction.subscriptionGroupID else {
                PRLogger.purchases.fault("Transaction has no group id!")
                return
            }
            
            if group == SubscriptionType.premiumSubscriptionGroupIdentifier {
                self.subscriptionType = .premium
            }
            
        case .unverified(let transaction, let error):
            PRLogger.purchases.warning("Received unverified transaction with id [\(transaction.id)] for product [\(transaction.productID, privacy: .public)].")
        }
    }
}

enum SubscriptionType: String {
    case free = "Free"
    case premium = "Premium"
    
    static let premiumSubscriptionGroupIdentifier = "21491764"
    
    enum PremiumLength: String {
        case monthly
        case yearly
        
        var productID: String {
            switch self {
            case .monthly:  return "com.ebuniapps.progress.subscriptions.premium.1m"
            case .yearly:   return "com.ebuniapps.progress.subscriptions.premium.1y"
            }
        }
    }
}
