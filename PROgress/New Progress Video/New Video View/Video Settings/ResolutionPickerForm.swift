//
//  ResolutionPickerForm.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 28..
//

import SwiftUI

extension NewProgressVideoView.VideoSettingsView {
    struct ResolutionPickerForm: View {
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        @State private var isPremiumUser: Bool = true
        @State private var numberFormatter: NumberFormatter = {
            var formatter = NumberFormatter()
            formatter.numberStyle = .none
            return formatter
        }()
        
        var body: some View {
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
                        HStack {
                            Text("Custom dimension")
                            
                            Spacer()
                            
                            Picker("", selection: $viewModel.userSettings.customExtentAxis) {
                                ForEach(customExtentAxisCases, id: \.self) { axis in
                                    Text(axis.displayName)
                                        .tag(axis)
                                }
                            }
                            .pickerStyle(.segmented)
                            .fixedSize()
                        }
                        
                        VStack {
                            HStack {
                                TextField("Width", value: $viewModel.userSettings.customExtent, formatter: numberFormatter)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            ResolutionPicker(resolution: $viewModel.userSettings.customExtent,
                                             customDimension: viewModel.userSettings.customExtentAxis)
                        }
                    } header: {
                        Text("Custom resolution (preserved aspect ratio)")
                    }
                    
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Resolution Picker")
        }
        
        private var footnoteAttributedString: AttributedString = {
            let regularTextPart = AttributedString("Some resolution types are only available with PROgress Premium subscription. ")
            var linkPart = AttributedString("More info...")
            linkPart.link = URL(string: "https://www.apple.com")
            
            return regularTextPart + linkPart
        }()
        
        private var resolutionCases = VideoProcessingUserSettings.Resolution.allCases
        private var customExtentAxisCases = Axis.allCases
    }
}

struct ResolutionPickerForm_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView.VideoSettingsView.ResolutionPickerForm()
    }
}
