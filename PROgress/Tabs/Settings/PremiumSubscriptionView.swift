//
//  PremiumSubscriptionView.swift
//  PROgress
//
//  Created by Balázs Erdész on 23/05/2024.
//

import SwiftUI
import StoreKit
import os

struct PremiumSubscriptionView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "21491764") {
            VStack {
                Text("PROgress Premium")
                    .font(.largeTitle).bold()
                
                Text("grants access to the following features:")
                    .font(.footnote)
                    .padding(.bottom, 40)
                
                VStack {
                    Text("High resolution videos")
                        .bold().foregroundStyle(.tint)
                    Text("up from 1280 pixels maximum in both extents")
                        .font(.caption2).foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                    
                    Text("Unlimited progress photo count")
                        .bold().foregroundStyle(.tint)
                    Text("up from 100 photos maximum")
                        .font(.caption2).foregroundStyle(.secondary)
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
    }
}

#Preview {
    Text("SSSS")
        .sheet(isPresented: .constant(true), content: {
            PremiumSubscriptionView()
        })
}
