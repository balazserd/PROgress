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
                        Text("Change \(Image(systemName: "chevron.right"))")
                            .font(.body)
                    }
                }
                
                HStack {
                    VStack {
                        HStack {
                            Text("Frame Length").font(.subheadline)
                            Spacer()
                            Text("\(viewModel.userSettings.timeBetweenFrames, specifier: "%.2f")s")
                                .settingsColumnDataStyle()
                        }
                        
                        HStack {
                            Text("Resolution").font(.subheadline)
                            Spacer()
                            Text("\(viewModel.userSettings.resolution.extraShortName)")
                                .settingsColumnDataStyle()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .padding(.leading, 8)
                    
                    VStack {
                        Text("Background").font(.subheadline)
                        Spacer()
                        Rectangle()
                            .fill(viewModel.userSettings.backgroundColor)
                            .frame(width: 20, height: 20)
                            .aspectRatio(1.0, contentMode: .fill)
                            .cornerRadius(2)
                            .shadow(color: .gray.opacity(0.4), radius: 8)
                    }
                    .frame(maxWidth: 110)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                Text("Selected photos: \(viewModel.progressImages!.count)")
                    .font(.title3)
                    .bold()
                    .padding(.bottom, -2)
                
                HStack(spacing: 0) {
                    Text("💡")
                        .font(.caption2)
                        .padding(.leading, -2)
                    Text("Long press and drag an image to reorder it.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                
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

fileprivate extension Text {
    func settingsColumnHeaderStyle() -> some View {
        self.font(.subheadline)
            .bold()
            .lineLimit(1)
    }
    
    func settingsColumnDataStyle() -> some View {
        self.font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}

struct ImageLoadingSuccessView_Previews: PreviewProvider {
    static var previews: some View {
        ImageLoadingSuccessView()
            .environmentObject(NewProgressVideoViewModel.previewForLoadedImagesView)
    }
}
