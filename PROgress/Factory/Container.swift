//
//  Container.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 09..
//

import Foundation
import Factory

extension Container {
    var imageMergeEngine: Factory<ImageMergeEngine> {
        self { ImageMergeEngine() }
    }
    
    var photoLibraryManager: Factory<PhotoLibraryManager> {
        self { PhotoLibraryManager() }
    }
    
    var activityManager: Factory<ActivityManager> {
        self { ActivityManager() }
    }
}
