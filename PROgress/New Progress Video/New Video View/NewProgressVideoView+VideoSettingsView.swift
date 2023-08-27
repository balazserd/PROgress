//
//  NewProgressVideoView+VideoSettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 27..
//

import Foundation
import SwiftUI

extension NewProgressVideoView {
    struct VideoSettingsView: View {
        @State private var isPremiumUser: Bool = false
        
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
                
                switch viewModel.userSettings.resolution {
                case .customWidthPreservedAspectRatio:
                    VStack {
                        HStack {
                            Text("Custom dimension")
                            
                            Picker("", selection: $viewModel.userSettings.customExtentAxis) {
                                ForEach(customExtentAxisCases, id: \.rawValue) { customExtentAxis in
                                    Text(customExtentAxis.displayName)
                                        .tag(customExtentAxis)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Text("of")
                        
                        
                        
                        Text("pixels")
                    }
                    
                case .custom:
                    Divider()
                    
                    Divider()
                    
                    
                default:
                    EmptyView()
                }
            }
            .navigationDestination(for: SubSetting.self) {
                switch $0 {
                case .resolution:
                    Form {
                        Section {
                            Picker(selection: $viewModel.userSettings.resolution) {
                                ForEach(resolutionCases, id: \.rawValue) { resolutionType in
                                    if resolutionType.isFree || isPremiumUser {
                                        Text(resolutionType.displayName)
                                            .foregroundColor(.primary)
                                            .tag(resolutionType)
                                    } else {
                                        Text(resolutionType.displayName)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                }
                            } label: {
                                EmptyView()
                            }
                            .pickerStyle(.inline)
                        } header: {
                            Text("Resolution Types")
                        } footer: {
                            if !isPremiumUser {
                                Text(footnoteAttributedString)
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
            let regularTextPart = AttributedString("Some resolution types are only available with PROgress PRO subscription. ")
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
