//
//  NewProgressVideoView+ImageProcessing.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 10..
//

import Foundation
import SwiftUI

extension NewProgressVideoView {
    struct VideoProcessingInProgressView: View {
        var progress: Double
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView(value: progress) {
                    Text("Creating progress video...")
                }
                
                Text("This operation might take a while. For faster processing, keep the app in the foreground.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 225)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
            )
        }
    }
    
    struct VideoProcessingFinishedView: View {
        var action: () -> Void
        
        var body: some View {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Your video is ready!")
                        .font(.title2).bold()
                    
                    Text("🎉🎉🎉")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    Button(
                        action: action,
                        label: {
                            Text("Let me see")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    
//                    Button(
//                        action: { },
//                        label: {
//                            Text("Save now into Photos app")
//                                .frame(maxWidth: .infinity)
//                        }
//                    )
//                    .buttonStyle(.bordered)
                }
            }
            .frame(maxWidth: 275)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.white)
            )
        }
    }
}

struct NewProgressVideoView_ImageProcessing: PreviewProvider {
    static var previews: some View {
        Group {
            NewProgressVideoView.VideoProcessingInProgressView(progress: 0.7)
            
            NewProgressVideoView.VideoProcessingFinishedView(action: { })
        }
    }
}
