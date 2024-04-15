//
//  ImageLoadingSuccessView+SettingsSection.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/03/2024.
//

import SwiftUI

extension ImageLoadingSuccessView {
    struct SettingsSection: View {
        @EnvironmentObject private var viewModel: NewProgressVideoViewModel
        
        var body: some View {
            HStack {
                VStack {
                    HStack {
                        Text("Frame Length").font(.subheadline)
                        Spacer()
                        Text("\(viewModel.userSettings.timeBetweenFrames, specifier: "%.2f")s")
                            .tableRowDataStyle()
                    }
                    
                    HStack {
                        Text("Resolution").font(.subheadline)
                        Spacer()
                        Text("\(viewModel.userSettings.resolution.extraShortName)")
                            .tableRowDataStyle()
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .padding(.leading, 8)
                
                VStack {
                    Text("Background").font(.subheadline)
                    Rectangle()
                        .fill(viewModel.userSettings.backgroundColor)
                        .frame(width: 20, height: 20)
                        .aspectRatio(1.0, contentMode: .fill)
                        .cornerRadius(2)
                        .shadow(color: .gray.opacity(0.4), radius: 8)
                }
                .frame(maxWidth: 110)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    let settings = VideoProcessingUserSettings()
    let vm = NewProgressVideoViewModel()
    vm.userSettings = settings
    
    return VStack {
        ImageLoadingSuccessView.SettingsSection()
            .environmentObject(vm)
        
        Rectangle()
            .foregroundStyle(Color.blue)
    }
}

