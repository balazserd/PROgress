//
//  PremiumSubscriptionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 23/05/2024.
//

import SwiftUI
import StoreKit
import os
import TipKit
import Combine

struct PremiumSubscriptionView: View {
    @State private var didShowTip: Bool = false
    @State private var showRedeemCodeSheet: Bool = false
    @State private var showManageSubscriptionsSheetWarning: Bool = false
    @State private var showManageSubscriptionsSheet: Bool = false
    
    @State private var productIDs: [String] = []
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    var body: some View {
        ScrollView {
            VStack {
                Text("PROgress Premium")
                    .font(.largeTitle).bold()
                    .padding(.top, 24)
                
                Text("grants access to the following features:")
                    .font(.footnote)
                    .padding(.bottom, 40)
                
                VStack(spacing: 8) {
                    premiumFeature(title: "High resolution videos", description: "up from 1280 pixels maximum in both extents")
                    
                    premiumFeature(title: "Unlimited progress photo count", description: "up from 100 photos maximum")
                    
                    premiumFeature(title: "No watermarks", description: "make it look professional")
                }
                
                if !didShowTip {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .bold()
                        Text("Which subscription duration is good for me?")
                    }
                    .font(.caption)
                    .foregroundStyle(.tint.opacity(0.7))
                    .subscriptionSelectionTip(didShowTip: $didShowTip)
                    .padding(.top, 24)
                }
                
                if self.productIDs.isEmpty {
                    ContentUnavailableView("You already have the highest tier of PROgress Premium.",
                                           systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.gray)
                } else {
                    StoreView(ids: self.productIDs)
                        .productViewStyle(.compact)
                        .storeButton(.visible, for: .restorePurchases)
                        .storeButton(.hidden, for: .cancellation)
                        .padding(.horizontal, -16)
                        .padding(.top, 40)
                        .frame(minHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Button(action: { showRedeemCodeSheet = true }) {
                    Text("Redeem Code")
                }
                .padding(.top, 12)
                
                Divider()
                    .padding(.top, 8)
                
                HStack {
                    Spacer()
                    
                    Link(destination: .privacyPolicy) {
                        Text("Privacy Policy")
                    }
                    Spacer()
                    Link(destination: .eula) {
                        Text("Terms of Use")
                    }
                    
                    Spacer()
                }
                .font(.footnote)
                .opacity(0.7)
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            LinearGradient(stops: [.init(color: Color.accentColor.opacity(0.1), location: 0),
                                   .init(color: Color(uiColor: .systemBackground), location: 1)],
                           startPoint: .top,
                           endPoint: .bottom)
        )
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptionsSheet,
                                  subscriptionGroupID: SubscriptionType.premiumSubscriptionGroupIdentifier)
        .offerCodeRedemption(isPresented: $showRedeemCodeSheet)
        .onReceive(
            Publishers.CombineLatest(globalSettings.$subscriptionType,
                                     globalSettings.$isPremiumUserWithRecurringPayments)
        ) { (currentSubscriptionType, isPremiumUserWithRecurringPayments) in
            let purchaseableProducts = SubscriptionType.allCases
                .filter { $0 > currentSubscriptionType }
            
            self.productIDs = purchaseableProducts.compactMap { $0.productID }
        
            if currentSubscriptionType == .premium_lifetime && isPremiumUserWithRecurringPayments {
                // Auto show manage subscription sheet to cancel
                showManageSubscriptionsSheetWarning = true
            }
        }
        .alert("Warning", isPresented: $showManageSubscriptionsSheetWarning) {
            Button(role: .cancel, action: {
                dismiss()
                showManageSubscriptionsSheet = true
            }) {
                Text("Manage...")
            }
            
            Button(role: .destructive, action: { dismiss() }) {
                Text("Not now")
            }
        } message: {
            Text("Thanks for buying Lifetime Premium! Make sure to **cancel any recurring subscriptions** you might have as it's not possible to cancel those automatically.")
        }
        
        // Version without lifetime premium
        #if false
        SubscriptionStoreView(groupID: SubscriptionType.premiumSubscriptionGroupIdentifier) {
            VStack {
                Text("PROgress Premium")
                    .font(.largeTitle).bold()
                
                Text("grants access to the following features:")
                    .font(.footnote)
                    .padding(.bottom, 40)
                
                VStack(spacing: 8) {
                    premiumFeature(title: "High resolution videos", description: "up from 1280 pixels maximum in both extents")
                    
                    premiumFeature(title: "Unlimited progress photo count", description: "up from 100 photos maximum")
                }
                
                if !didShowTip {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 16, height: 16)
                            .bold()
                        Text("Which subscription duration is good for me?")
                    }
                    .font(.caption)
                    .foregroundStyle(.tint.opacity(0.7))
                    .subscriptionSelectionTip(didShowTip: $didShowTip)
                    .padding(.top, 24)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .containerBackground(for: .subscriptionStore) {
                LinearGradient(stops: [.init(color: Color.accentColor.opacity(0.1), location: 0),
                                       .init(color: Color.accentColor.opacity(0.03), location: 0.85),
                                       .init(color: Color.white, location: 1)],
                               startPoint: .top,
                               endPoint: .bottom)
            }
            .padding(.top, 12)
        }
        .backgroundStyle(.clear)
        .subscriptionStoreControlStyle(.prominentPicker)
        .onInAppPurchaseCompletion { product, result in
            switch result {
            case .success(let purchaseResult):
                PRLogger.purchases.notice("Finished in-app purchase successful! [\(String(describing: purchaseResult))]")
                NotificationCenter.default.post(name: .didPurchaseItem, object: nil)
                
            case .failure(let error):
                PRLogger.purchases.error("In app purchase completion resulted in error! [\(error)]")
            }
        }
        .storeButton(.visible, for: .redeemCode)
        #endif
    }
    
    func premiumFeature(title: String, description: String) -> some View {
        VStack {
            Text(title)
                .bold().foregroundStyle(.tint)
            Text(description)
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    Button(action: { }) {
        Text("Button")
    }
        .popoverTip(SubscriptionSelectionTip())
        .sheet(isPresented: .constant(true), content: {
            PremiumSubscriptionView()
                .environmentObject(GlobalSettings.shared)
        })
}
