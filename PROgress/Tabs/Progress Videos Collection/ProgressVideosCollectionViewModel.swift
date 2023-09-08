//
//  ProgressVideosCollectionViewModel.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 07..
//

import Foundation
import Factory

class ProgressVideosCollectionViewModel: ObservableObject {
    @Injected(\.photoLibraryManager) private var photoLibraryManager: PhotoLibraryManager
}
