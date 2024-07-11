//
//  VideoCreationLiveActivity.swift
//  PROgressActivities
//
//  Created by Balázs Erdész on 2023. 08. 20..
//

import ActivityKit
import WidgetKit
import SwiftUI
import Combine

struct VideoCreationLiveActivity: Widget {
    @AppStorage(.privateActivitiesMode, store: .appGroup) private var privateActivitiesMode: Bool = false
    
    private typealias Context = ActivityViewContext<VideoCreationLiveActivityAttributes>
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VideoCreationLiveActivityAttributes.self) { context in
            notificationContent(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                expandedContent(context: context)
            } compactLeading: {
                compactLeadingContent(firstImage: context.attributes.firstImage,
                                      lastImage: context.attributes.lastImage,
                                      progress: context.state.progress)
                .transition(.identity)
            } compactTrailing: {
                minimalContent(progress: context.state.progress)
                    .transition(.identity)
            } minimal: {
                minimalContent(progress: context.state.progress)
                    .transition(.identity)
            }
        }
    }
    
    // MARK: - Notification presentation components
    private func notificationContent(context: Self.Context) -> some View {
        VStack {
            if privateActivitiesMode {
                privateMiddleContent(progress: context.state.progress)
                    .frame(height: 70)
                    .contentTransition(.identity)
            } else {
                VStack {
                    middleContent(firstImage: context.attributes.firstImage,
                                  middleImages: context.attributes.middleImages,
                                  lastImage: context.attributes.lastImage)
                    
                    bottomContent(description: context.state.description,
                                  progress: context.state.progress)
                    .contentTransition(.identity)
                }
                .frame(height: 110)
            }
        }
        .padding(16)
    }
    
    // MARK: - Expanded presentation components
    @DynamicIslandExpandedContentBuilder
    private func expandedContent(context: Self.Context) -> DynamicIslandExpandedContent<some View> {
        DynamicIslandExpandedRegion(.bottom) {
            if !privateActivitiesMode {
                bottomContent(description: context.state.description,
                              progress: context.state.progress)
                .padding([.horizontal], 10)
                .contentTransition(.identity)
            }
        }
        
        DynamicIslandExpandedRegion(.center) {
            if privateActivitiesMode {
                privateMiddleContent(progress: context.state.progress)
            } else {
                middleContent(firstImage: context.attributes.firstImage,
                              middleImages: context.attributes.middleImages,
                              lastImage: context.attributes.lastImage)
                .padding(.horizontal, 10)
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
    
    private func privateMiddleContent(progress: Double) -> some View {
        VStack {
            Spacer(minLength: 0)
            
            HStack {
                VStack(alignment: .leading) {
                    if progress.isLess(than: 1.0) {
                        Text("Creating your video...")
                        Text(progress, format: .percent.precision(.fractionLength(0)).rounded(rule: .up))
                            .font(.largeTitle)
                            .bold()
                            .contentTransition(.identity)
                    } else {
                        Text("Ready!")
                            .font(.title)
                            .bold()
                        
                        Text("Tap this notification to check the result.")
                            .font(.caption)
                    }
                }
                .layoutPriority(.infinity)
                
                Spacer(minLength: 25)
                
                minimalContent(progress: progress, scale: .large)
            }
        }
    }
    
    // MARK: - Compact presentation components
    @ViewBuilder
    private func compactLeadingContent(firstImage: URL?, lastImage: URL?, progress: Double) -> some View {
        if privateActivitiesMode {
            Text(progress, format: .percent.precision(.fractionLength(0)).rounded(rule: .up))
                .contentTransition(.identity)
        } else {
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
    }
    
    // MARK: - Minimal presentation components
    private func minimalContent(progress: Double, scale: Image.Scale = .small) -> some View {
        ProgressView(value: progress) {
            Image(uiImage: UIImage(named: "PROgressAppIcon")!)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: scale == .large ? 35 : 12,
                       maxHeight: scale == .large ? 35 : 12)
                .opacity(0.8)
                .imageScale(.small)
                .foregroundColor(.accentColor.opacity(0.5))
        }
        .progressViewStyle(.circular)
        .frame(height: scale == .large ? nil : 25.0)
        .tint(.green)
    }
    
    // MARK: - Reused components
    private func thumbnailImage(url: URL?, scale: Image.Scale) -> some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1.0, contentMode: .fit)
            .overlay {
                if  let url,
                    let uiImage = UIImage(contentsOfFile: url.path()) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .contentTransition(.identity)
                } else {
                    Image(systemName: "photo.circle")
                        .imageScale(scale)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: scale == .large ? 8 : 3))
            .layoutPriority(scale == .large ? 1.0 : 0.5)
            .contentTransition(.identity)
    }
}

// MARK: - Previews
struct PROgressActivitiesLiveActivity_Previews: PreviewProvider {
    static let url = URL(string: "/Users/balazserdesz/Downloads/xxx.jpg")
    static let attributes = VideoCreationLiveActivityAttributes(
        firstImage: Self.url,
        middleImages: [Self.url, Self.url, Self.url],
        lastImage: Self.url
    )
    static var contentState = VideoCreationLiveActivityAttributes.ContentState(progress: 0.00, description: "Creating your video...")

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
