//
//  ImageLoadingSuccessView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

@preconcurrency import SwiftUI
import EBUniAppsKit

struct ImageLoadingSuccessView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    
    @State private var draggedImage: ProgressImage?
    
    var body: some View {
        VStack(alignment: .leading) {
            
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
                    ForEach(viewModel.progressImages) {
                        PhotoGridItem(progressImage: $0,
                                      draggedImage: $draggedImage,
                                      isInFilteringMode: $viewModel.isInFilteringMode)
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
        .toolbar { Self.Toolbar(selectionModeToggle: $viewModel.isInFilteringMode) }
        .frame(maxHeight: .infinity)
        .padding(8)
        .navigationTitle("Selected Photos (\(viewModel.progressImages.count))")
    }
    
    private var gridColumnCount: Int {
        if self.horizontalSizeClass == .compact {
            self.verticalSizeClass == .regular ? 4 : 8
        } else {
            8
        }
    }
    
    private struct Toolbar: ToolbarContent {
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        @Binding var selectionModeToggle: Bool
        
        @State private var reverseButtonAnimation: Bool = false
        
        // This warning thrown here is fixed by Apple on iOS 18: `@MainActor @preconcurrency protocol ToolbarContent`
        var body: some ToolbarContent {
            if selectionModeToggle {
                ToolbarItem {
                    Button(action: {
                        viewModel.excludeMarkedProgressImages()
                        selectionModeToggle = false
                    }) {
                        Image(systemName: "trash.fill")
                            .tint(.red)
                    }
                    .disabled(viewModel.imagesToExclude.isEmpty)
                }
            }
            
            ToolbarItem {
                Button(action: {
                    selectionModeToggle.toggle()
                }) {
                    if selectionModeToggle {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            
            ToolbarItem {
                Button(action: {
                    reverseButtonAnimation.toggle()
                    
                    viewModel.photoUserOrdering.reverse()
                    viewModel.progressImages.reverse()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .rotationEffect(reverseButtonAnimation ? .degrees(180) : .degrees(0))
                        .animation(.default, value: reverseButtonAnimation)
                }
            }
        }
    }
}

struct ImageLoadingSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        ImageLoadingSuccessView()
            .environmentObject(NewProgressVideoViewModel.previewForLoadedImagesView)
    }
}
