//
//  ProgressVideoCollectionItem.swift
//  PROgress
//
//  Created by Balázs Erdész on 29/04/2024.
//

import SwiftUI

struct ProgressVideoCollectionItem: View {
    @EnvironmentObject private var viewModel: ProgressVideosCollectionViewModel
    
    var video: VideoAsset
    
    @Binding var isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(video.name)
                        .font(.title3)
                        .bold()
                        .lineLimit(1)
                    
                    if let date = video.creationDate {
                        Text(DateFormatter.videoDateFormatter.string(from: date))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                NavigationLink(value: video) {
                    Text("Watch \(Image(systemName: "chevron.right"))")
                }
            }
            
            
            HStack {
                self.progressImage(from: video.firstImage, isLarge: true)
                
                ForEach(0..<3, id: \.self) { index in
                    Spacer()
                    
                    self.progressImage(from: video.middleImages[index], isLarge: false)
                }
                
                Spacer()
                
                self.progressImage(from: video.lastImage, isLarge: true)
            }
        }
        .opacity(isEditing ? 0.4 : 1.0)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 12)
                .background {
                    if isEditing {
                        RoundedRectangle(cornerRadius: 10)
                            .inset(by: -2)
                            .stroke(.red, lineWidth: viewModel.shouldRemoveVideo(video) ? 2 : 0)
                            .transition(editingTransition)
                    }
                }
        }
        .overlay(alignment: .topLeading) {
            if isEditing && viewModel.shouldRemoveVideo(video) {
                ZStack(alignment: .topLeading, content: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.red.opacity(0.05))
                    
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .symbolRenderingMode(.multicolor)
                        .frame(width: 24, height: 24)
                        .offset(x: -12, y: -12)
                })
                .transition(editingTransition)
            }
        }
        .animation(.easeInOut, value: isEditing)
    }
    
    private var editingTransition: AnyTransition {
        AnyTransition.asymmetric(insertion: .opacity,
                                 removal: .identity)
    }
    
    private static var largeProgressImageSize = 80.0
    private static var smallProgressImageSize = 60.0
    
    private func progressImage(from uiImage: UIImage?, isLarge: Bool) -> some View {
        Rectangle()
            .fill(.clear)
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                Image(uiImage: uiImage ?? .init(systemName: "photo")!)
                    .resizable()
                    .scaledToFill()
            }
            .cornerRadius(4)
            .clipped()
            .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
            .frame(maxWidth: isLarge ? Self.largeProgressImageSize : Self.smallProgressImageSize,
                   maxHeight: isLarge ? Self.largeProgressImageSize : Self.smallProgressImageSize)
    }
}

#Preview {
    ProgressVideoCollectionItem(video: .init(middleImages: [nil, nil, nil], length: 320, index: 7, localIdentifier: "dfdgfdgfdgfgd"), isEditing: .constant(true))
        .environmentObject(ProgressVideosCollectionViewModel())
}
