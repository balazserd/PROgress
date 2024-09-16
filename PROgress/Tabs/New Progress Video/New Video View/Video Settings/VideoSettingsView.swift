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
    
    @State private var isShowingSubscriptionsSheet = false
    
    var body: some View {
        Form {
            Section {
                NavigationLink(value: VideoSubsetting.photoSelector) {
                    HStack {
                        if !globalSettings.isPremiumUser && viewModel.progressImages.count > 100 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                        
                        Text("\(viewModel.progressImages.count) photo(s) selected")
                        
                        Spacer()
                    }
                }
            } header: {
                Text("Photos")
            } footer: {
                if !globalSettings.isPremiumUser && viewModel.progressImages.count > 100 {
                    Text(max100PhotosAttributedString)
                        .font(.caption)
                        .subscriptionSheetLink(isPresented: $isShowingSubscriptionsSheet)
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
    
    private let max100PhotosAttributedString: AttributedString = {
        var boldPart = AttributedString("Only the first 100 Photos will be used.")
        boldPart.foregroundColor = .red
        boldPart.font = .system(.caption2, weight: .bold)
        
        var regularPart = AttributedString(" Upgrade to Premium if you want to create a video of unlimited number of photos. ")
        
        var linkPart = AttributedString("More info...")
        linkPart.link = .openSubscriptionSheet
        
        return boldPart + regularPart + linkPart
    }()
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
