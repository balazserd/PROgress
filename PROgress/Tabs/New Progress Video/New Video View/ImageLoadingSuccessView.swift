//
//  ImageLoadingSuccessView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

import SwiftUI
import EBUniAppsKit

struct ImageLoadingSuccessView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    
    @State private var draggedImage: ProgressImage?
    
    var body: some View {
//        VStack(alignment: .leading) {
//            HStack {
//                Text("Settings")
//                    .font(.title3)
//                    .bold()
//                
//                Spacer()
//                
//                NavigationLink(value: NavigationDestination.settings) {
//                    Text("Change \(Image(systemName: "chevron.right"))")
//                        .font(.body)
//                }
//            }
            
//            SettingsSection()
            
//            Divider()
            
            VStack(alignment: .leading) {
//                Text("Selected photos: \(viewModel.progressImages!.count)")
//                    .font(.title3)
//                    .bold()
//                    .padding(.bottom, -2)
                
                HStack(spacing: 0) {
                    Text("💡")
                        .font(.caption2)
                        .padding(.leading, -2)
                    Text("Long press and drag an image to reorder it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                    
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(), count: gridColumnCount)) {
                        ForEach(viewModel.progressImages!) {
                            PhotoGridItem(progressImage: $0, draggedImage: $draggedImage)
                        }
                    }
                    
                    if viewModel.video != nil {
                        // Space for the "Watch video" button
                        Color.clear.frame(height: 32)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, -8)
                .contentMargins([.horizontal, .bottom], 8, for: .scrollContent)
            }
            .frame(maxHeight: .infinity)
//        }
        .padding(8)
        .navigationTitle("Selected Photos (\(viewModel.progressImages?.count ?? 0))")
    }
    
    private var gridColumnCount: Int {
        if self.horizontalSizeClass == .compact {
            self.verticalSizeClass == .regular ? 4 : 8
        } else {
            8
        }
    }
}

struct ImageLoadingSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        ImageLoadingSuccessView()
            .environmentObject(NewProgressVideoViewModel.previewForLoadedImagesView)
    }
}
