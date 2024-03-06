//
//  StatusBar.swift
//  PROgress
//
//  Created by Balázs Erdész on 06/03/2024.
//

import Foundation
import SwiftUI

struct StatusBar<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack {
            content()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                )
                .padding(.bottom, 32)
        }
    }
}

struct StatusBar_Previews: PreviewProvider {
    static var previews: some View {
        StatusBar {
            ProgressView {
                Text("Saving video...")
            }
        }
        
        StatusBar {
            VStack {
                Button(action: { }, label: {
                    Text("Press me")
                })
                
                Text("Hey!")
                    .foregroundStyle(.secondary)
                
                ProgressView(value: 0.6)
            }
        }
    }
}
