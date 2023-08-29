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
                        NavigationLink(value: SubSetting.customResolutionPicker) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Custom Dimensions")
                                Text("\(viewModel.userSettings.width, specifier: "%d") x \(viewModel.userSettings.height, specifier: "%d")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Video Settings")
            .navigationDestination(for: SubSetting.self) {
                switch $0 {
                case .resolutionTypePicker:
                    ResolutionPickerForm()
                case .customResolutionPicker:
                    CustomResolutionPickerPage()
                }
            }
        }
        
        private var framesPerSecond: Double {
            1.0 / viewModel.userSettings.timeBetweenFrames
        }
    }
}

fileprivate enum SubSetting {
    case resolutionTypePicker
    case customResolutionPicker
}

struct VideoSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewProgressVideoView.VideoSettingsView()
                .environmentObject(NewProgressVideoViewModel())
        }
    }
}
