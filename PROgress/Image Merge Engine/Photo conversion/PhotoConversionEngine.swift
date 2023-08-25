//
//  PhotoConversionEngine.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 18..
//

import Foundation
import Photos
import PhotosUI
import SwiftUI
import Factory

// MARK: - Protocol definition
protocol PhotoConversionEngine: Sendable {
    associatedtype Input: Hashable, Sendable
    
    /// Converts the appropriate input to its `Data` representation.
    ///
    /// - Throws: The underlying error that arose during conversion.
    func convertInput(_ input: Input) async throws -> Data
}

// MARK: - Implementation: PHAsset
extension PhotoConversionEngine where Self == PHAssetConversionEngine {
    static func phAssetEngine(options: PHImageRequestOptions? = nil) -> Self { .init(options: options) }
}

class PHAssetConversionEngine: PhotoConversionEngine, @unchecked Sendable {
    typealias LocalIdentifier = String
    
    @Injected(\.photoLibraryManager) private var photoLibraryManager
    
    let options: PHImageRequestOptions?
    
    init(options: PHImageRequestOptions? = nil) {
        self.options = options
    }
    
    func convertInput(_ input: LocalIdentifier) async throws -> Data {
        let asset = try photoLibraryManager.assetForIdentifier(input)
        
        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default()
                .requestImageDataAndOrientation(for: asset, options: self.options) { data, _, _, resultInfo in
                    guard let data = data else {
                        let info = resultInfo ?? [:]
                        PRLogger.photoConversion.error("Image data could not be loaded! \(info.debugDescription)")
                        
                        continuation.resume(throwing: ConversionError.imageRequestError)
                        return
                    }
                    
                    continuation.resume(returning: data)
                }
        }
    }
    
    enum ConversionError: Error {
        case imageRequestError
    }
}

// MARK: - Implementation: PhotosPickerItem
extension PhotoConversionEngine where Self == PhotosPickerItemConversionEngine {
    static var photosPickerItemEngine: Self { .init() }
}

final class PhotosPickerItemConversionEngine: PhotoConversionEngine {
    func convertInput(_ input: PhotosPickerItem) async throws -> Data {
        guard let data = try await input.loadTransferable(type: Data.self) else {
            throw ConversionError.transferableLoadError
        }
        
        return data
    }
    
    enum ConversionError: Error {
        case transferableLoadError
    }
}
