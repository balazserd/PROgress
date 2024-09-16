//
//  ProgressVideoCollectionGrid.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import SwiftUI
import EBUniAppsKit

@DeviceDependent
struct ProgressVideoCollectionGrid<Content: View>: View {
    @Binding var orientation: UIDeviceOrientation
    
    @ViewBuilder var content: Content
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 20) {
            content
        }
    }
    
    private let oneColumnGrid = [GridItem()]
    private let twoColumnGrid = [GridItem(spacing: 20), GridItem(spacing: 20)]
    
    private var gridItems: [GridItem] {
        if isIpad && [.landscapeLeft, .landscapeRight].contains(orientation) {
            return oneColumnGrid
        }
        
        if self.horizontalSizeClass == .compact {
            return self.verticalSizeClass == .regular ? oneColumnGrid : twoColumnGrid
        } else {
            return twoColumnGrid
        }
    }
}
