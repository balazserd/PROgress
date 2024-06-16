//
//  ImageLoadingSuccessView+PhotoGridItem.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/03/2024.
//

import SwiftUI

extension ImageLoadingSuccessView {
    struct PhotoGridItem: View {
        var progressImage: ProgressImage
        @Binding var draggedImage: ProgressImage?
        @Binding var isInFilteringMode: Bool
        
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        @State private var isReordering: Bool = false
        
        var body: some View {
            Rectangle()
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    progressImage.image
                        .resizable()
                        .scaledToFill()
                        .onTapGesture {
                            // TODO: open image
                        }
                    
                    if viewModel.shouldExcludeProgressImage(progressImage) {
                        Color.red.opacity(0.6)
                    }
                }
                .cornerRadius(4)
                .clipped()
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                .scaleEffect(of: (isReordering || viewModel.shouldExcludeProgressImage(progressImage)) ? 0.85 : 1.0)
                .animation(.linear(duration: 0.2), value: isReordering)
                .opacity(isReordering ? 0.8 : 1.0)
                .opacity(viewModel.shouldExcludeProgressImage(progressImage) ? 0.2 : 1.0)
                .overlay(alignment: .topTrailing) {
                    if viewModel.shouldExcludeProgressImage(progressImage) {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                }
                .onDrag { beginDrag(for: progressImage ) }
                .onDrop(of: [.text], delegate: buildDropDelegate(for: progressImage))
                .highPriorityGesture(
                    TapGesture()
                        .onEnded {
                            guard isInFilteringMode else { return }
                            viewModel.toggleExclusionStatus(for: progressImage)
                        }
                )
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
    }
}
