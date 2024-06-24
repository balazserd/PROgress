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
    @Published var subscriptionTransaction: Transaction?
    
    @Published var purchaseRestorationInProgress: Bool = false
    
    var isPremiumUser: Bool { self.subscriptionType == .premium }
    
    // MARK: - Initializer
    static let shared = GlobalSettings()
    private init() {
        setupSubscriptions()
    }
    
    // MARK: - Public operations
    func requestPurchaseRestore() {
        self.purchaseRestorationInProgress = true
        
        Task {
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    // At least 2 seconds timeout between restores.
                    try await Task.sleep(for: .seconds(2))
                }
                
                group.addTask {
                    try await AppStore.sync()
                    
                    for await verificationResult in Transaction.unfinished {
                        if case let .verified(transaction) = verificationResult {
                            PRLogger.purchases.debug("Unfinished transaction found!")
                            await transaction.finish()
                        }
                    }
                    
                    await self.refreshPurchaseStates()
                }
            }
            
            self.purchaseRestorationInProgress = false
        }
    }
    
    // MARK: - Private operations
    private nonisolated func setupSubscriptions() {
        Task(priority: .background) {
            for await _notification in NotificationCenter.default.notifications(named: .didPurchaseItem) {
                await self.refreshPurchaseStates()
            }
        }
        
        Task(priority: .background) {
            for await _update in Transaction.updates {
                PRLogger.purchases.debug("Received update to a transaction. Refreshing purchase states...")
                await self.refreshPurchaseStates()
            }
        }
    }
    
    private func refreshPurchaseStates() async {
        PRLogger.purchases.debug("Will refresh subscription states.")
        
        for await verificationResult in Transaction.currentEntitlements {
            await assertTransactionVerificationResult(verificationResult)
        }
    }
    
    private func assertTransactionVerificationResult(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let transaction):
            PRLogger.purchases.debug("Received verified transaction with id [\(transaction.id)] for product [\(transaction.productID, privacy: .public)].")
            guard let group = transaction.subscriptionGroupID else {
                PRLogger.purchases.fault("Transaction has no group id!")
                return
            }
            
            if group == SubscriptionType.premiumSubscriptionGroupIdentifier {
                if transaction.expired {
                    PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) has expired on \(transaction.expirationDate ?? .distantPast)!")
                    self.subscriptionType = .free
                } else {
                    PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) is live!")
                    self.subscriptionType = .premium
                    self.subscriptionTransaction = transaction
                }
                
                await transaction.finish()
            }
            
        case .unverified(let transaction, let _error):
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
