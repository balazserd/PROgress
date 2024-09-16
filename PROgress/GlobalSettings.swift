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
    
    var isPremiumUser: Bool { self.subscriptionType > .free }
    
    @Published private(set) var isPremiumUserWithRecurringPayments: Bool = false
    private var currentProductIDs: [String] = [] {
        didSet {
            let recurringProductIDs = [SubscriptionType.premium_monthly, .premium_yearly].map { $0.productID }
            isPremiumUserWithRecurringPayments = currentProductIDs
                .filter { recurringProductIDs.contains($0) }
                .count > 0
        }
    }
    
    let maximumNumberOfPhotosForFreeUser = 100
    
    // MARK: - Initializer
    static let shared = GlobalSettings()
    private init() {
        setupSubscriptions()
        
        Task {
            await self.refreshPurchaseStates()
        }
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
            for await _ in NotificationCenter.default.notifications(named: .didPurchaseItem) {
                await self.refreshPurchaseStates()
            }
        }
        
        Task(priority: .background) {
            for await _ in Transaction.updates {
                PRLogger.purchases.debug("Received update to a transaction. Refreshing purchase states...")
                await self.refreshPurchaseStates()
            }
        }
    }
    
    private func refreshPurchaseStates() async {
        PRLogger.purchases.debug("Will refresh subscription states.")
        
        self.currentProductIDs.removeAll()
        
        for await verificationResult in Transaction.currentEntitlements {
            await assertTransactionVerificationResult(verificationResult)
        }
    }
    
    private func assertTransactionVerificationResult(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .verified(let transaction):
            PRLogger.purchases.debug("Received verified transaction with id [\(transaction.id)] for product [\(transaction.productID, privacy: .public)].")
            
            if let group = transaction.subscriptionGroupID {
                guard group == SubscriptionType.premiumSubscriptionGroupIdentifier else {
                    PRLogger.purchases.error("Unknown group ID! [\(group, privacy: .public)]")
                    return
                }
                
                if transaction.expired {
                    PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) has expired on \(transaction.expirationDate ?? .distantPast)!")
                } else {
                    PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) is live!")
                    guard let subscription = SubscriptionType(productId: transaction.productID) else {
                        PRLogger.purchases.error("Unrecocnized product ID!")
                        return
                    }
                    
                    do {
                        guard let product = try await Product.products(for: [transaction.productID]).first else {
                            PRLogger.purchases.error("Product not found! [id: \(transaction.productID, privacy: .public)]")
                            return
                        }
                        
                        let renewalInfos = try await product.subscription?.status.compactMap {
                            if case .verified(let renewalInfo) = $0.renewalInfo {
                                return renewalInfo
                            }
                            
                            return nil
                        }
                        
                        if renewalInfos?.filter({ $0.willAutoRenew }).isEmpty == false {
                            self.currentProductIDs.append(transaction.productID)
                        }
                    } catch let error {
                        PRLogger.purchases.error("Product fetching failed! [\(error)]")
                        return
                    }
                    
                    
                    guard self.subscriptionType < subscription else {
                        PRLogger.purchases.debug("The subscription type is not higher order than the currently existing one!")
                        return
                    }
                    
                    self.subscriptionType = subscription
                    self.subscriptionTransaction = transaction
                }
                
                await transaction.finish()
            } else if transaction.productID == SubscriptionType.premium_lifetime.productID {
                guard transaction.revocationDate == nil else {
                    PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) is revoked!")
                    return
                }
                
                PRLogger.purchases.debug("Transaction with product ID \(transaction.productID, privacy: .public) is live!")
                
                self.currentProductIDs.append(transaction.productID)
                
                self.subscriptionType = .premium_lifetime
                self.subscriptionTransaction = transaction
                
                await transaction.finish()
            }
            
        case .unverified(let transaction, let error):
            PRLogger.purchases.warning("Received unverified transaction with id [\(transaction.id)] for product [\(transaction.productID, privacy: .public)]. Error: \(error)")
        }
    }
}

enum SubscriptionType: Int, CaseIterable, Comparable {
    case free = 0
    case premium_monthly
    case premium_yearly
    case premium_lifetime
    
    static let premiumSubscriptionGroupIdentifier = "21491764"
    
    init?(productId: String) {
        if let _self = Self.allCases.first(where: { $0.productID == productId }) {
            self = _self
        } else {
            return nil
        }
    }
    
    var productID: String? {
        switch self {
        case .free:             return nil
        case .premium_monthly:  return "com.ebuniapps.progress.subscriptions.premium.1m"
        case .premium_yearly:   return "com.ebuniapps.progress.subscriptions.premium.1y"
        case .premium_lifetime: return "com.ebuniapps.progress.iap.premium.lifetime"
        }
    }
    
    var typeDescription: String {
        self == .free ? "Free" : "Premium"
    }
    
    static func < (lhs: SubscriptionType, rhs: SubscriptionType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
