//
//  ResolutionPickerForm.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 28..
//

import SwiftUI

struct ResolutionPickerForm: View {
    @EnvironmentObject private var viewModel: NewProgressVideoViewModel
    @EnvironmentObject private var globalSettings: GlobalSettings
    
    var body: some View {
        Form {
            Section {
                Picker(selection: $viewModel.userSettings.resolution) {
                    ForEach(resolutionCases, id: \.rawValue) { resolutionType in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(resolutionType.displayName)
                                .foregroundColor(resolutionType.isFreeTierOption || globalSettings.isPremiumUser ? .primary : .secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            
                            if let length = resolutionType.maxExtentLength {
                                Text("Maximum size in pixels in either direction: \(length, specifier: "%.0f")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .conditionalTag(resolutionType.isFreeTierOption || globalSettings.isPremiumUser,
                                        tag: resolutionType as VideoProcessingUserSettings.Resolution?)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.inline)
            } header: {
                Text("Options")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PROgress cannot upscale your images, even if you select a larger resolution.")
                    
                    if !globalSettings.isPremiumUser {
                        Text(footnoteAttributedString)
                    }
                }
            }
        }
        .navigationTitle("Resolution")
    }
    
    private var footnoteAttributedString: AttributedString = {
        let regularTextPart = AttributedString("Some resolution types are only available with PROgress Premium subscription. ")
        var linkPart = AttributedString("More info...")
        linkPart.link = URL(string: "https://www.apple.com")
        
        return regularTextPart + linkPart
    }()
    
    private var resolutionCases = VideoProcessingUserSettings.Resolution.allCases
}

struct ResolutionPickerForm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ResolutionPickerForm()
                .environmentObject(NewProgressVideoViewModel.previewForVideoSettings)
                .environmentObject(GlobalSettings())
        }
    }
}
