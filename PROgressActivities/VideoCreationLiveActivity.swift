//
//  VideoCreationLiveActivity.swift
//  PROgressActivities
//
//  Created by Balázs Erdész on 2023. 08. 20..
//

import ActivityKit
import WidgetKit
import SwiftUI

struct VideoCreationLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var progress: Double
    }

    // Fixed non-changing properties about your activity go here!
    var firstImage: Data?
    var middleImages: [Data?]
    var lastImage: Data?
    var title: String
}

struct VideoCreationLiveActivity: Widget {
    private typealias Context = ActivityViewContext<VideoCreationLiveActivityAttributes>
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VideoCreationLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                middleContent(for: context)
                
                bottomContent(for: context)
            }
            .frame(height: 110)
            .padding(16)
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    bottomContent(for: context)
                        .padding([.horizontal], 10)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    middleContent(for: context)
                        .padding(.horizontal, 10)
                }
            } compactLeading: {
                compactTrailingContent(for: context)
            } compactTrailing: {
                minimalContent(for: context)
            } minimal: {
                minimalContent(for: context)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
    
    // MARK: - Large presentation components
    private func bottomContent(for context: Context) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(context.attributes.title)
                .font(.caption)
            
            ProgressView(value: context.state.progress)
        }
    }
    
    private func middleContent(for context: Context) -> some View {
        HStack {
            self.image(for: context.attributes.lastImage, scale: .large)
            
            Image(systemName: "arrow.forward")
                .imageScale(.small)
                .opacity(0.5)
            
            ForEach(0..<3) { middleImageIndex in
                self.image(for: context.attributes.middleImages[middleImageIndex], scale: .small)
                
                Image(systemName: "arrow.forward")
                    .imageScale(.small)
                    .opacity(0.5)
            }
            
            self.image(for: context.attributes.firstImage, scale: .large)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Compact presentation components
    private func compactTrailingContent(for context: Context) -> some View {
        HStack(spacing: 4) {
            self.image(for: context.attributes.firstImage, scale: .medium)
                .frame(height: 25)
            
            Image(systemName: "arrow.forward")
                .imageScale(.small)
            
            self.image(for: context.attributes.lastImage, scale: .medium)
                .frame(height: 25)
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Minimal presentation components
    private func minimalContent(for context: Context) -> some View {
        ProgressView(value: context.state.progress) {
            Image(systemName: "photo.stack")
                .imageScale(.small)
                .foregroundColor(.accentColor.opacity(0.5))
        }
        .progressViewStyle(.circular)
        .frame(height: 25)
        .tint(.accentColor)
    }
    
    // MARK: - Reused components
    @ViewBuilder
    private func image(for data: Data?, scale: Image.Scale) -> some View {
        ZStack {
            if  let imageData = data,
                let uiImage = UIImage(data: imageData)
            {
                Image(uiImage: uiImage)
                    .aspectRatio(1.0, contentMode: .fit)
            } else {
                Color.accentColor.opacity(0.7)
                    .overlay {
                        Image(systemName: "photo.circle")
                            .imageScale(scale)
                    }
                    .aspectRatio(1.0, contentMode: .fit)
            }
        }
        .cornerRadius(scale == .large ? 8 : 3)
        .layoutPriority(scale == .large ? 1.0 : 0.5)
    }
}

struct PROgressActivitiesLiveActivity_Previews: PreviewProvider {
    static let attributes = VideoCreationLiveActivityAttributes(
        firstImage: nil,
        middleImages: [nil, nil, nil],
        lastImage: nil,
        title: "Creating your video..."
    )
    static let contentState = VideoCreationLiveActivityAttributes.ContentState(progress: 0.77)

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
