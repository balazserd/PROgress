//
//  ProgressImage.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import SwiftUI
import Foundation

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
