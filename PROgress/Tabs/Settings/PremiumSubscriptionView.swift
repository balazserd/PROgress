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

struct PremiumSubscriptionView: View {
    @State private var didShowTip: Bool = false
    @State private var showRedeemCodeSheet: Bool = false
    @State private var showManageSubscriptionsSheet: Bool = false
    
    @State private var productIDs: [String] = []
    
    var body: some View {
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
            
            StoreView(ids: self.productIDs)
                .productViewStyle(.compact)
                .storeButton(.visible, for: .restorePurchases)
                .storeButton(.hidden, for: .cancellation)
                .padding(.horizontal, -16)
                .padding(.top, 40)
            
            Button(action: { showRedeemCodeSheet = true }, label: {
                Text("Redeem Code")
            })
        }
        .padding(16)
        .background(
            LinearGradient(stops: [.init(color: Color.accentColor.opacity(0.1), location: 0),
                                   .init(color: Color.white, location: 1)],
                           startPoint: .top,
                           endPoint: .bottom)
        )
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptionsSheet,
                                  subscriptionGroupID: SubscriptionType.premiumSubscriptionGroupIdentifier)
        .offerCodeRedemption(isPresented: $showRedeemCodeSheet)
        .onReceive(GlobalSettings.shared.$subscriptionType) { currentSubscriptionType in
            let purchaseableProducts = SubscriptionType.allCases
                .filter { $0 > currentSubscriptionType }
            
            self.productIDs = purchaseableProducts.compactMap { $0.productID }
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
        })
}
