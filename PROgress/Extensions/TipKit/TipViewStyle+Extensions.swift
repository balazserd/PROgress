//
//  TipViewStyle+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/07/2024.
//

import Foundation
import TipKit

struct PRTipViewStyle: TipViewStyle {
    @Binding var didShowTip: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Tip")
                }
                .bold()
                .foregroundStyle(.tint)
                
                configuration.title
                    .font(.footnote).bold()
                
                configuration.message
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.leading)
            
            Image(systemName: "xmark").scaledToFit()
                .onTapGesture {
                    configuration.tip.invalidate(reason: .tipClosed)
                }
                .frame(width: 12, height: 12)
                .foregroundStyle(.secondary)
        }
        .padding()
        .onDisappear(perform: {
            withAnimation {
                didShowTip = true
            }
        })
    }
}
