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
        NavigationStack {
            switch viewModel.state {
            case .undefined:
                PhotosPicker(selection: $viewModel.selectedItems, matching: .any(of: [.images, .screenshots])) {
                    Text("Select photos")
                }
                
            case .loading:
                VStack {
                    ProgressView(value: viewModel.loadingProgress) {
                        Text("Importing photos...")
                    }
                    
                    Text("Depending on the count of selected photos, this operation might take a few minutes.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            case .failure:
                Text("Loading the image failed!")
                
            case .success(let progressImages):
                ScrollView {
                    LazyVGrid(columns: Array(repeating: .init(), count: 5)) {
                        ForEach(progressImages) { progressImage in
                            Rectangle()
                                .aspectRatio(1, contentMode: .fill)
                                .overlay {
                                    progressImage.image
                                        .resizable()
                                        .scaledToFill()
                                }
                                .cornerRadius(8)
                                .clipped()
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
            
        }
    }
}

struct NewProgressVideoView_Previews: PreviewProvider {
    static var previews: some View {
        NewProgressVideoView()
    }
}
