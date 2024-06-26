//
//  ReorderImagesDropDelegate.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 12..
//

import Foundation
import SwiftUI
import PhotosUI

struct ReorderImagesDropDelegate: DropDelegate {
    /// The ``ProgressImage`` this delegate instance is attached to.
    let parent: ProgressImage
    let onReorderEnded: (() -> Void)?
    
    // Must follow index changes here too!
    @Binding var photoUserOrdering: [Int]
    
    @Binding var allProgressImages: [ProgressImage]
    @Binding var currentlyMovedImage: ProgressImage?
    
    func dropEntered(info: DropInfo) {
        guard parent != currentlyMovedImage else {
            return
        }
        
        guard
            currentlyMovedImage != nil,
            !allProgressImages.isEmpty,
            let dragIndex = allProgressImages.firstIndex(of: currentlyMovedImage!),
            let dropIndex = allProgressImages.firstIndex(of: parent)
        else {
            PRLogger.app.error("DropDelegate misses items!")
            return
        }
        
        allProgressImages.move(fromOffsets: IndexSet([dragIndex]),
                               toOffset: dropIndex > dragIndex ? dropIndex + 1 : dropIndex)
        
        photoUserOrdering.move(fromOffsets: IndexSet([dragIndex]),
                               toOffset: dropIndex > dragIndex ? dropIndex + 1 : dropIndex)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.currentlyMovedImage = nil
        self.onReorderEnded?()
        
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
