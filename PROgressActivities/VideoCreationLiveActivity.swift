//
//  VideoCreationLiveActivity.swift
//  PROgressActivities
//
//  Created by Balázs Erdész on 2023. 08. 20..
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VideoCreationLiveActivity: Widget {
    private typealias Context = ActivityViewContext<VideoCreationLiveActivityAttributes>
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VideoCreationLiveActivityAttributes.self) { context in
            VStack {
                middleContent(firstImage: context.attributes.firstImage,
                              middleImages: context.attributes.middleImages,
                              lastImage: context.attributes.lastImage)
                
                bottomContent(description: context.state.description,
                              progress: context.state.progress)
                    .contentTransition(.identity)
            }
            .frame(height: 110)
            .padding(16)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    bottomContent(description: context.state.description,
                                  progress: context.state.progress)
                        .padding([.horizontal], 10)
                        .contentTransition(.identity)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    middleContent(firstImage: context.attributes.firstImage,
                                  middleImages: context.attributes.middleImages,
                                  lastImage: context.attributes.lastImage)
                        .padding(.horizontal, 10)
                }
            } compactLeading: {
                compactTrailingContent(firstImage: context.attributes.firstImage,
                                       lastImage: context.attributes.lastImage)
            } compactTrailing: {
                minimalContent(progress: context.state.progress)
                    .transition(.identity)
            } minimal: {
                minimalContent(progress: context.state.progress)
                    .transition(.identity)
            }
        }
    }
    
    // MARK: - Large presentation components
    private func bottomContent(description: String, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(description)
                .font(.caption)
            
            ProgressView(value: progress)
        }
    }
    
    private func middleContent(firstImage: URL?, middleImages: [URL?], lastImage: URL?) -> some View {
        HStack(spacing: 6) {
            thumbnailImage(url: firstImage, scale: .large)
            
            Image(systemName: "arrow.forward")
                .imageScale(.small)
                .opacity(0.5)
            
            ForEach(0..<3) { middleImageIndex in
                thumbnailImage(url: middleImages[middleImageIndex], scale: .small)
                
                Image(systemName: "arrow.forward")
                    .imageScale(.small)
                    .opacity(0.5)
            }
            
            thumbnailImage(url: lastImage, scale: .large)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Compact presentation components
    private func compactTrailingContent(firstImage: URL?, lastImage: URL?) -> some View {
        HStack(spacing: 4) {
            thumbnailImage(url: firstImage, scale: .medium)
                .frame(height: 25)
            
            Image(systemName: "arrow.forward")
                .imageScale(.small)
                .opacity(0.5)
            
            thumbnailImage(url: lastImage, scale: .medium)
                .frame(height: 25)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Minimal presentation components
    private func minimalContent(progress: Double) -> some View {
        ProgressView(value: progress) {
            Image(systemName: "photo.stack")
                .imageScale(.small)
                .foregroundColor(.accentColor.opacity(0.5))
        }
        .progressViewStyle(.circular)
        .frame(height: 25)
        .tint(.accentColor)
    }
    
    // MARK: - Reused components
    private func thumbnailImage(url: URL?, scale: Image.Scale) -> some View {
        ZStack {
            Color.accentColor.opacity(0.7)
                .overlay {
                    Image(systemName: "photo.circle")
                        .imageScale(scale)
                }
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    if  let url,
                        let uiImage = UIImage(contentsOfFile: url.path()) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .contentTransition(.identity)
                    }
                }
        }
        .cornerRadius(scale == .large ? 8 : 3)
        .layoutPriority(scale == .large ? 1.0 : 0.5)
    }
}

struct PROgressActivitiesLiveActivity_Previews: PreviewProvider {
    static let url = URL(string: "/Users/balazserdesz/Downloads/xxx.jpg")
    static let attributes = VideoCreationLiveActivityAttributes(
        firstImage: Self.url,
        middleImages: [Self.url, Self.url, Self.url],
        lastImage: Self.url
    )
    static let contentState = VideoCreationLiveActivityAttributes.ContentState(progress: 0.77, description: "Creating your video...")

    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Island Compact")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Island Expanded")
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Minimal")
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Notification")
    }
}
