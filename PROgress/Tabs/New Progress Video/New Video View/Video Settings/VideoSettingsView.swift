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
            Section("Photos") {
                NavigationLink(value: VideoSubsetting.photoSelector) {
                    Text("\(viewModel.progressImages?.count ?? -1) photo(s) selected")
                }
            }
            
            BasicVideoSettingsSection()
            
            PremiumVideoSettingsSection()
            
            if viewModel.video != nil {
                Button(action: { viewModel.watchVideo() }) {
                    HStack {
                        Spacer()
                        Text("Watch video").bold()
                        Spacer()
                    }
                }
            }
        }
        .navigationDestination(for: ProgressVideo.self) { progressVideo in
            NewProgressVideoPlayerView(video: progressVideo)
        }
        .navigationDestination(for: VideoSubsetting.self) {
            switch $0 {
            case .resolutionTypePicker:
                ResolutionPickerForm()
            case .aspectRatioFixedCustomResolutionPicker:
                AspectRatioFixedResolutionPickerPage()
            case .freeCustomResolutionPicker:
                FreeResolutionPickerPage()
            case .photoSelector:
                ImageLoadingSuccessView()
            }
        }
    }
}

struct VideoSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VideoSettingsView()
                .environmentObject(NewProgressVideoViewModel.previewForVideoSettings)
                .environmentObject(GlobalSettings.shared)
        }
    }
}
