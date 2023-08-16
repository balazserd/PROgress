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
import AVKit

struct NewProgressVideoView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var isReordering: Bool = false
    @State private var draggedImage: ProgressImage?
    
    @State private var isShowingPhotoPicker: Bool = false
    
    @StateObject private var viewModel = NewProgressVideoViewModel()
    
    var body: some View {
        ZStack {
            NavigationStack(path: $viewModel.navigationState) {
                VStack {
                    switch viewModel.imageLoadingState {
                    case .undefined:
                        PhotosPicker(selection: $viewModel.selectedItems,
                                     matching: .any(of: [.images, .screenshots])) {
                            Text("Select photos")
                        }
                        
                    case .loading(let progress):
                        loadingView(progress)
                        
                    case .failure:
                        Text("Loading the image failed!")
                        
                    case .success:
                        ImageLoadingSuccessView()
                    }
                }
                .navigationTitle("New progress video")
                .navigationDestination(for: ProgressVideo.self) { progressVideo in
                    NewProgressVideoPlayerView(video: progressVideo)
                }
                .toolbar { toolbar }
                .overlay(alignment: .bottom) {
                    if viewModel.video != nil {
                        Button(action: { viewModel.watchVideo() }) {
                            Text("Watch video")
                                .bold()
                                .frame(maxWidth: .infinity, minHeight: 32)
                        }
                        .padding(8)
                        .buttonStyle(.borderedProminent)
                    }
                }
                .photosPicker(isPresented: $isShowingPhotoPicker,
                              selection: $viewModel.selectedItems,
                              matching: .any(of: [.images, .screenshots]))
            }
                
            switch viewModel.videoProcessingState {
            case .idle:
                EmptyView()
                
            case .working(let progress):
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture(perform: { viewModel.resetVideoProcessingState() })
                
                VideoProcessingInProgressView(progress: progress)
                    .transition(.opacity.animation(.linear(duration: 0.3)))
                
            case .finished:
                Color.gray
                    .opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture(perform: { viewModel.resetVideoProcessingState() })
                
                VideoProcessingFinishedView(action: { viewModel.watchVideo() })
                    .transition(.opacity.animation(.linear(duration: 0.3)))
            }
        }
        .environmentObject(self.viewModel)
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button(action: { isShowingPhotoPicker = true }) {
                    Label("Select photos", systemImage: "photo.stack")
                }
                
                Button(action: { }) {
                    Label("Select a folder", systemImage: "folder")
                }
            } label: {
                Image(systemName: "plus")
            }
        }
        
        if viewModel.selectedItems.count > 0 {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.beginMerge() }) {
                    Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                }
                .disabled(!viewModel.imageLoadingState.isSuccess)
            }
        }
    }
}

struct NewProgressVideoView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView()
    }
}
