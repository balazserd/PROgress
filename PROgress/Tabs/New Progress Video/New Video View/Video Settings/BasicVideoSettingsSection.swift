//
//  BasicVideoSettingsSection.swift
//  PROgress
//
//  Created by Balázs Erdész on 15/04/2024.
//

import SwiftUI

struct BasicVideoSettingsSection: View {
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    
    var body: some View {
        Section("Basic") {
            VStack(alignment: .leading) {
                Stepper("Time between images: \(viewModel.userSettings.timeBetweenFrames, specifier: "%.2f")s",
                        value: $viewModel.userSettings.timeBetweenFrames,
                        in: 0.05...5.0,
                        step: 0.05)
                
                Text("This will result in ~\(framesPerSecond, specifier: "%.1f") images per second in the video.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            NavigationLink(value: VideoSubsetting.resolutionTypePicker) {
                HStack {
                    Text("Resolution")
                    
                    Spacer()
                    
                    Text(viewModel.userSettings.resolution.shortName)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.userSettings.resolution == .customWidthPreservedAspectRatio {
                NavigationLink(value: VideoSubsetting.aspectRatioFixedCustomResolutionPicker) {
                    customResolutionNavigationLinkLabel
                }
            } else if viewModel.userSettings.resolution == .custom {
                NavigationLink(value: VideoSubsetting.freeCustomResolutionPicker) {
                    customResolutionNavigationLinkLabel
                }
            } else {
                VStack(alignment: .leading) {
                    Picker("Shape", selection: $viewModel.userSettings.shape) {
                        ForEach(shapeCases, id: \.rawValue) { shapeType in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(shapeType.rawValue)
                                
                                
                            }
                            .tag(shapeType)
                        }
                    }
                    
                    Text(viewModel.userSettings.shape.complimentaryText)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, -4)
            }
            
            ColorPicker(selection: $viewModel.userSettings.backgroundColor) {
                Text("Background fill color")
            }
        }
    }
    
    private var framesPerSecond: Double {
        1.0 / viewModel.userSettings.timeBetweenFrames
    }
    
    private var customResolutionNavigationLinkLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Custom Dimensions")
            Text("\(viewModel.userSettings.extentX, specifier: "%.0f") x \(viewModel.userSettings.extentY, specifier: "%.0f")")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var shapeCases = VideoProcessingUserSettings.Shape.allCases
}

// MARK: - Preview
#Preview {
    BasicVideoSettingsSection()
}
