//
//  ProgressImage.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import SwiftUI
import Foundation

struct ProgressImage: Transferable, Hashable, Identifiable, @unchecked Sendable {
    let image: Image
    let id = UUID()
    var localIdentifier: String!
    let originalSize: CGSize
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard
                let uiImage = UIImage(data: data),
                let scaledDownImage = await uiImage.byPreparingThumbnail(ofSize: CGSize(width: 640, height: 480))
            else {
                throw PhotoTransferingError.invalidUIImage
            }
            
            let loadedImage = Image(uiImage: scaledDownImage)
            return ProgressImage(image: loadedImage, originalSize: uiImage.size)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @available(*, deprecated, message: "Use when transferable export is required for ProgressImage.")
    struct Identifier: Hashable, Transferable {
        var id: UUID
        
        static var transferRepresentation: some TransferRepresentation {
            ProxyRepresentation(
                exporting: \.id.uuidString,
                importing: {
                    guard let uuid = UUID(uuidString: $0) else {
                        throw TransferableError.invalidUUIDString
                    }
                    
                    return Identifier(id: uuid)
                }
            )
        }
        
        enum TransferableError: Error {
            case invalidUUIDString
        }
    }
}
