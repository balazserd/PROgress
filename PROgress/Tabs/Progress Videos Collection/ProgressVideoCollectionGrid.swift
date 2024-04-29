//
//  ProgressVideoCollectionGrid.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import SwiftUI

struct ProgressVideoCollectionGrid<Content: View>: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ViewBuilder
    var content: Content
    
    var body: some View {
        LazyVGrid(columns: gridItems, spacing: 20) {
            content
        }
    }
    
    private let oneColumnGrid = [GridItem()]
    private let twoColumnGrid = [GridItem(spacing: 20), GridItem(spacing: 20)]
    
    private var gridItems: [GridItem] {
        if self.horizontalSizeClass == .compact {
            self.verticalSizeClass == .regular ? oneColumnGrid : twoColumnGrid
        } else {
            twoColumnGrid
        }
    }
}

#Preview {
    ProgressVideoCollectionGrid {
        
    }
}
