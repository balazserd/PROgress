//
//  NewProgressVideoView+VideoSettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 27..
//

import Foundation
import EBUniAppsKit
import SwiftUI

extension NewProgressVideoView {
    struct VideoSettingsView: View {
        @State private var isPremiumUser: Bool = true
        
        enum SubSetting {
            case resolution
        }
        
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        var body: some View {
            Form {
                VStack(alignment: .leading) {
                    Stepper("Time between images: \(viewModel.userSettings.timeBetweenFrames, specifier: "%.2f")s",
                            value: $viewModel.userSettings.timeBetweenFrames,
                            in: 0.05...5.0,
                            step: 0.05)
                    
                    Text("This will result in ~\(framesPerSecond, specifier: "%.1f") images per second in the video.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(value: SubSetting.resolution) {
                    HStack {
                        Text("Resolution")
                        
                        Spacer()
                        
                        Text(viewModel.userSettings.resolution.shortName)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Video Settings")
            .navigationDestination(for: SubSetting.self) {
                switch $0 {
                case .resolution:
                    Form {
                        Section {
                            Picker(selection: $viewModel.userSettings.resolution) {
                                ForEach(resolutionCases, id: \.rawValue) { resolutionType in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(resolutionType.displayName)
                                            .foregroundColor(resolutionType.isFree || isPremiumUser ? .primary : .secondary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        
                                        if let length = resolutionType.maxExtentLength {
                                            Text("Maximum size in pixels in either direction: \(length)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .conditionalTag(resolutionType.isFree || isPremiumUser, tag: resolutionType)
                                }
                            } label: {
                                EmptyView()
                            }
                            .pickerStyle(.inline)
                        } header: {
                            Text("Resolution Types")
                        } footer: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PROgress cannot upscale your images, even if you select a larger resolution.")
                                
                                if !isPremiumUser {
                                    Text(footnoteAttributedString)
                                }
                            }
                        }
                        
                        switch viewModel.userSettings.resolution {
                        case .custom:
                            Section {
                                
                            } header: {
                                Text("Custom settings")
                            }
                            
                        case .customWidthPreservedAspectRatio:
                            Section {
                                
                            } header: {
                                Text("Custom settings")
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                    .navigationTitle("Resolution Picker")
                }
            }
        }
        
        private var footnoteAttributedString: AttributedString = {
            let regularTextPart = AttributedString("Some resolution types are only available with PROgress Premium subscription. ")
            var linkPart = AttributedString("More info...")
            linkPart.link = URL(string: "https://www.apple.com")
            
            return regularTextPart + linkPart
        }()
        
        private var frameDuration: Double {
            viewModel.userSettings.timeBetweenFrames
        }
        
        private var framesPerSecond: Double {
            1.0 / viewModel.userSettings.timeBetweenFrames
        }
        
        private var resolutionCases = VideoProcessingUserSettings.Resolution.allCases
        private var customExtentAxisCases = VideoProcessingUserSettings.CustomExtentAxis.allCases
    }
}

struct VideoSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProgressVideoView.VideoSettingsView()
                .environmentObject(NewProgressVideoViewModel())
        }
    }
}
