//
//  NewProgressVideoView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI
import PhotosUI
import Combine
import CoreData

struct NewProgressVideoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var viewModel = NewProgressVideoViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    switch viewModel.imageLoadingState {
                    case .undefined:
                        PhotosPicker(selection: $viewModel.selectedItems, matching: .any(of: [.images, .screenshots])) {
                            Text("Select photos")
                        }
                        
                    case .loading(let progress):
                        loadingView(progress)
                        
                    case .failure:
                        Text("Loading the image failed!")
                        
                    case .success(let progressImages):
                        successView(progressImages)
                    }
                }
                .navigationTitle("New progress video")
                .toolbar { toolbar }
            }
                
            switch viewModel.videoProcessingState {
            case .idle:
                EmptyView()
                
            case .working(let progress):
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VideoProcessingInProgressView(progress: progress)
                    .animation(.linear, value: viewModel.videoProcessingState)
                
            case .finished:
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VideoProcessingFinishedView(action: { viewModel.clearVideoProcessingState() })
                    .animation(.linear, value: viewModel.videoProcessingState)
            }
        }
    }
    
    private func loadingView(_ progress: Double) -> some View {
        VStack(alignment: .leading) {
            ProgressView(value: progress) {
                Text("Importing photos...")
            }
            
            Text("Depending on the number of selected photos, this operation might take a few minutes.")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func successView(_ progressImages: [ProgressImage]) -> some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(), count: 4)) {
                ForEach(progressImages) { progressImage in
                    Rectangle()
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            progressImage.image
                                .resizable()
                                .scaledToFill()
                        }
                        .cornerRadius(4)
                        .clipped()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 2, y: 2)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            PhotosPicker(selection: $viewModel.selectedItems, matching: .any(of: [.images, .screenshots])) {
                Image(systemName: "plus")
            }
        }
        
        ToolbarItem(placement: .primaryAction) {
            Button(action: { viewModel.beginMerge() }) {
                Image(systemName: "gearshape.arrow.triangle.2.circlepath")
            }
        }
    }
}

struct NewProgressVideoView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView()
    }
}
