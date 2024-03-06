//
//  NewProgressVideoView+ImageProcessingModals.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 10..
//

import Foundation
import SwiftUI

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
            VStack(alignment: .leading, spacing: 8) {
                Text("Your video is ready!")
                    .font(.title2).bold()
                
                Text("Your progress video is done processing. You can now view, save and share it or continue editing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(
                    action: action,
                    label: {
                        Text("See video")
                            .bold()
                            .frame(maxWidth: .infinity)
                    }
                )
                .buttonStyle(.borderedProminent)
                .padding(.top)
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

struct NewProgressVideoView_ImageProcessing: PreviewProvider {
    static var previews: some View {
        Group {
            VideoProcessingInProgressView(progress: 0.7)
            
            VideoProcessingFinishedView(action: { })
        }
    }
}
