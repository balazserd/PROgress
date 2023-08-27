//
//  NewProgressVideoView+ImageLoadingSuccessView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

import SwiftUI
import EBUniAppsKit

extension NewProgressVideoView {
    struct ImageLoadingSuccessView: View {
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        @Environment(\.verticalSizeClass) var verticalSizeClass
        
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        enum NavigationDestination {
            case settings
        }
        
        @State private var isReordering: Bool = false
        @State private var draggedImage: ProgressImage?
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Settings")
                            .font(.title3)
                            .bold()
                        
                        Spacer()
                        
                        NavigationLink(value: NavigationDestination.settings) {
                            Text("View")
                        }
                    }
                    
                    Divider()
                    
                    Text("Selected photos (\(viewModel.progressImages!.count))")
                        .font(.title3)
                        .bold()
                    
                    Text("Tip: long press and drag an image to reorder it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: .init(), count: gridColumnCount)) {
                        ForEach(viewModel.progressImages!) { progressImage in
                            photoGridItem(for: progressImage)
                        }
                    }
                    
                    if viewModel.video != nil {
                        // Space for the "Watch video" button
                        Color.clear.frame(height: 32 + 2 * 12)
                    }
                }
                .padding(.horizontal, 8)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .settings:
                    VideoSettingsView()
                }
            }
        }
        
        private func photoGridItem(for progressImage: ProgressImage) -> some View {
            Rectangle()
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    progressImage.image
                        .resizable()
                        .scaledToFill()
                        .onTapGesture {
                            // TODO: open image
                        }
                }
                .cornerRadius(4)
                .clipped()
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                .scaleEffect(of: isReordering ? 0.85 : 1.0)
                .animation(.linear(duration: 0.2), value: isReordering)
                .opacity(isReordering ? 0.8 : 1.0)
                .onDrag {
                    beginDrag(for: progressImage)
                }
                .onDrop(of: [.text], delegate: buildDropDelegate(for: progressImage))
                .animation(.default, value: viewModel.progressImages)
        }
        
        private func beginDrag(for progressImage: ProgressImage) -> NSItemProvider {
            draggedImage = progressImage
            isReordering = true
            
            return NSItemProvider(object: progressImage.id.uuidString as NSString)
        }
        
        private func buildDropDelegate(for progressImage: ProgressImage) -> ReorderImagesDropDelegate {
            ReorderImagesDropDelegate(parent: progressImage,
                                      onReorderEnded: { isReordering = false },
                                      photoUserOrdering: $viewModel.photoUserOrdering,
                                      allProgressImages: $viewModel.progressImages,
                                      currentlyMovedImage: $draggedImage)
        }
        
        private var gridColumnCount: Int {
            guard self.horizontalSizeClass == .compact else { return 8 }
            
            return self.verticalSizeClass == .regular ? 4 : 8
        }
    }
}

struct NewProgressVideoView_ImageLoadingSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView.ImageLoadingSuccessView()
    }
}
