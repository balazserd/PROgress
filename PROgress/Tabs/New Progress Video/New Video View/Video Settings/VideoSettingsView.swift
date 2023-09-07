//
//  VideoSettingsView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 27..
//

import Foundation
import EBUniAppsKit
import SwiftUI

struct VideoSettingsView: View {
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    var body: some View {
        Form {
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
            
            Section {
                Toggle(isOn: $viewModel.userSettings.hideLogo) {
                    Text("Hide PROgress logo")
                        .foregroundColor(globalSettings.isPremiumUser ? .primary : .secondary)
                }
                .disabled(!globalSettings.isPremiumUser)
                
                VStack(alignment: .leading) {
                    Toggle(isOn: $viewModel.userSettings.addBeforeAfterFinalImage) {
                        Text("Add before-after image as last frame")
                    }
                    
                    Text("A final frame is appended to the video that shows the first and the last photo side-by-side.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .foregroundColor(globalSettings.isPremiumUser ? .primary : .secondary)
                .disabled(!globalSettings.isPremiumUser)
            } header: {
                Text("Premium")
            } footer: {
                if !globalSettings.isPremiumUser {
                    Text(onlyWithPremiumAttributedString)
                        .font(.caption)
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
    
    private var onlyWithPremiumAttributedString: AttributedString = {
        let regularTextPart = AttributedString("These options are only available with PROgress Premium subscription. ")
        var linkPart = AttributedString("More info...")
        linkPart.link = URL(string: "https://www.apple.com")
        
        return regularTextPart + linkPart
    }()
    
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

fileprivate enum SubSetting {
    case resolutionTypePicker
    case aspectRatioFixedCustomResolutionPicker
    case freeCustomResolutionPicker
}

struct VideoSettingsView_Previews: PreviewProvider {    
    static var previews: some View {
        NavigationStack {
            VideoSettingsView()
                .environmentObject(NewProgressVideoViewModel.previewForVideoSettings)
                .environmentObject(GlobalSettings())
        }
    }
}
