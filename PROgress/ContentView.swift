//
//  ContentView.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 02..
//

import SwiftUI
import PhotosUI
import Combine
import CoreData

struct ContentView: View {
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
                ProgressView()
                
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

struct ProgressImage: Transferable, Identifiable {
    let image: Image
    let id = UUID()
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard
                let uiImage = UIImage(data: data),
                let scaledDownImage = await uiImage.byPreparingThumbnail(ofSize: CGSize(width: 640, height: 480))
            else {
                throw PhotoTransferingError.invalidUIImage
            }
            
            let loadedImage = Image(uiImage: scaledDownImage)
            return ProgressImage(image: loadedImage)
        }
    }
}

enum PhotoTransferingError: Error {
    /// The file cannot be imported as a `UIImage`.
    case invalidUIImage
}

@MainActor
class NewProgressVideoViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = [] {
        didSet {
            Task.detached { await self.loadImages(from: self.selectedItems) }
        }
    }
    
    @Published private(set) var state: ImageLoadingState = .undefined
    
    private nonisolated func loadImages(from selection: [PhotosPickerItem]) async {
        guard await selectedItems.count > 0 else {
            return
        }
        
        await updateState(to: .loading)
        
        do {
            let progressImageArray = try await withThrowingTaskGroup(of: ProgressImage?.self) { group in
                let maxConcurrentTasks = max(ProcessInfo().activeProcessorCount - 2, 1)
                var images = [ProgressImage?]()
                
                for index in 0..<maxConcurrentTasks {
                    group.addTask {
                        return try await selection[index].loadTransferable(type: ProgressImage.self)
                    }
                }
                
                var nextPhotoIndex = maxConcurrentTasks
                while let photo = try await group.next() {
                    guard photo != nil else { break }
                    
                    if nextPhotoIndex < selection.count {
                        group.addTask { [nextPhotoIndex] in
                            return try await selection[nextPhotoIndex].loadTransferable(type: ProgressImage.self)
                        }
                    }
                    
                    nextPhotoIndex += 1
                    
                    images.append(photo)
                }
                
                return images.compactMap { $0 }
            }
            
            PRLogger.app.debug("Successfully imported \(progressImageArray.count) photos")
            await updateState(to: .success(progressImageArray))
        } catch let error {
            PRLogger.app.error("Failed to fetch images! [\(error)]")
            await updateState(to: .failure(error))
        }
    }
    
    private func updateState(to state: ImageLoadingState) {
        self.state = state
    }
    
    enum ImageLoadingState {
        case undefined
        case loading
        case success([ProgressImage])
        case failure(Error)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
