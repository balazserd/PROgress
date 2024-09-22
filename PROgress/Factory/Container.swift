//
//  Container.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 09..
//

import Foundation
import Factory
import SwiftData

extension Container {
    var imageMergeEngine: Factory<ImageMergeEngine> {
        self { ImageMergeEngine() }
    }
    
    var photoLibraryManager: Factory<PhotoLibraryManager> {
        self { PhotoLibraryManager() }
    }
    
    #if canImport(ActivityKit)
    var activityManager: Factory<ActivityManager> {
        self { ActivityManager() }
    }
    #endif
    
    var persistenceContainer: Factory<ModelContainer?> {
        self {
            try? ModelContainer(for: ProgressVideo.Model.self)
        }
    }
}
