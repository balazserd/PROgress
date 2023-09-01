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
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        var body: some View {
            Form {
                Section("Basics") {
                    VStack(alignment: .leading) {
                        Stepper("Time between images: \(viewModel.userSettings.timeBetweenFrames, specifier: "%.2f")s",
                                value: $viewModel.userSettings.timeBetweenFrames,
                                in: 0.05...5.0,
                                step: 0.05)
                        
                        Text("This will result in ~\(framesPerSecond, specifier: "%.1f") images per second in the video.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    NavigationLink(value: SubSetting.resolutionTypePicker) {
                        HStack {
                            Text("Resolution")
                            
                            Spacer()
                            
                            Text(viewModel.userSettings.resolution.shortName)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.userSettings.resolution == .customWidthPreservedAspectRatio {
                        NavigationLink(value: SubSetting.aspectRatioFixedCustomResolutionPicker) {
                            customResolutionNavigationLinkLabel
                        }
                    } else if viewModel.userSettings.resolution == .custom {
                        NavigationLink(value: SubSetting.freeCustomResolutionPicker) {
                            customResolutionNavigationLinkLabel
                        }
                    }
                    
                    ColorPicker(selection: $viewModel.userSettings.backgroundColor) {
                        HStack {
                            Text("Background fill color")
                            
                            Rectangle()
                                .fill(viewModel.userSettings.backgroundColor)
                                .frame(width: 20, height: 20)
                                .aspectRatio(1.0, contentMode: .fill)
                                .cornerRadius(2)
                                .shadow(color: .gray.opacity(0.4), radius: 8)
                        }
                    }
                }
            }
            .navigationTitle("Video Settings")
            .navigationDestination(for: SubSetting.self) {
                switch $0 {
                case .resolutionTypePicker:
                    ResolutionPickerForm()
                case .aspectRatioFixedCustomResolutionPicker:
                    AspectRatioFixedResolutionPickerPage()
                case .freeCustomResolutionPicker:
                    FreeResolutionPickerPage()
                }
            }
        }
        
        private var customResolutionNavigationLinkLabel: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Custom Dimensions")
                Text("\(viewModel.userSettings.extentX, specifier: "%.0f") x \(viewModel.userSettings.extentY, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        
        private var framesPerSecond: Double {
            1.0 / viewModel.userSettings.timeBetweenFrames
        }
    }
}

fileprivate enum SubSetting {
    case resolutionTypePicker
    case aspectRatioFixedCustomResolutionPicker
    case freeCustomResolutionPicker
}

struct VideoSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProgressVideoView.VideoSettingsView()
                .environmentObject(NewProgressVideoViewModel())
        }
    }
}
