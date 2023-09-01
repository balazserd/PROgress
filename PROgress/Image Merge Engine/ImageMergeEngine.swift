//
//  ImageMergeEngine.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 09..
//

import Foundation
import SwiftUI
import PhotosUI
import CoreImage
import AVFoundation
import EBUniAppsKit
import Combine

actor ImageMergeEngine {
    static let backgroundTaskName = "com.ebuniapps.PROgress-imageMergeTask"
    
    var state = CurrentValueSubject<State, Never>(.idle)
    
    func provideVideoCreationActivityThumbnails<ConversionEngine: PhotoConversionEngine>(
        from images: [ConversionEngine.Input],
        by engine: ConversionEngine
    ) async throws -> VideoCreationActivityThumbnailData {
        typealias IndexedThumbnailUrl = (url: URL?, index: Int)
        let thumbnailDatas = try await withThrowingTaskGroup(of: IndexedThumbnailUrl.self) { group in
            guard images.count > 0 else {
                throw VideoCreationThumbnailActivityError.zeroImageCount
            }
            
            var items = [(images.first!, 0, "first"), (nil, 1, "middle1"), (nil, 2, "middle2"), (nil, 3, "middle3"), (images.first!, 4, "last")]
            if images.count > 1 {
                items[4] = (images.last!, 4, "last")
            }
            
            if images.count > 4 {
                let step = images.count / 4
                
                items[1] = (images[step * 1], 1, "middle1")
                items[2] = (images[step * 2], 2, "middle2")
                items[3] = (images[step * 3], 3, "middle3")
            }
            
            for item in items {
                group.addTask {
                    guard item.0 != nil else { return IndexedThumbnailUrl(nil, item.1) }
                    
                    let originalSizedData = try await engine.convertInput(item.0!)
                    guard
                        let uiImage = UIImage(data: originalSizedData),
                        let thumbnailUiImage = await uiImage.byPreparingThumbnail(ofSize: CGSize(width: 240, height: 240)),
                        let thumbnailData = thumbnailUiImage.jpegData(compressionQuality: 1.0)
                    else {
                        PRLogger.imageProcessing.error("Could not create UIImage from data!")
                        throw VideoCreationThumbnailActivityError.thumbnailImageCreation
                    }
                    
                    guard let fileUrl = FileManager.default
                        .containerURL(forSecurityApplicationGroupIdentifier: PROgressApp.groupIdentifier)?
                        .appendingPathComponent("videocreation-\(item.2).png") else {
                        throw VideoCreationThumbnailActivityError.appGroupNotFound
                    }
                    
                    try thumbnailData.write(to: fileUrl)
                    
                    return IndexedThumbnailUrl(url: fileUrl, index: item.1)
                }
            }
            
            var indexedThumbnailUrls = [IndexedThumbnailUrl]()
            for try await thumbnailUrl in group {
                indexedThumbnailUrls.append(thumbnailUrl)
            }
            
            return indexedThumbnailUrls
        }
        .sorted(by: { $0.index < $1.index })
        .map { $0.url }
        
        return VideoCreationActivityThumbnailData(firstImageData: thumbnailDatas.first!,
                                                  middleImagesData: Array(thumbnailDatas[1...3]),
                                                  lastImageData: thumbnailDatas.last!)
    }
    
    func mergeImages<ConversionEngine: PhotoConversionEngine>(
        _ _images: [ConversionEngine.Input],
        by engine: ConversionEngine,
        options: MergeOptions
    ) async throws -> ProgressVideo {
        var indexedImages = _images.map { ($0, _images.firstIndex(of: $0)!) }
        if let order = options.customOrder {
            indexedImages = order.map { indexedImages[$0] }
        }
        
        let ciContext = CIContext()
        
        let assetWriterConfig = try VideoAssetWriterConfiguration(settings: options.userSettings)
        guard assetWriterConfig.assetWriter.startWriting() else {
            let error = assetWriterConfig.assetWriter.error
            let status = assetWriterConfig.assetWriter.status.rawValue
            
            PRLogger.imageProcessing.error("Failed to start asset writing! [status: \(status)] [error: \(error)]")
            
            throw MergeError.assetWriterStartFailure
        }
        
        state.send(.working(progress: 0.0))
        
        assetWriterConfig.assetWriter.startSession(atSourceTime: .zero)
        
        let taskLimit = ProcessInfo.recommendedMaximumConcurrency
        let count = indexedImages.count
        try await indexedImages.mapConcurrentlyThenPerformSeriallyAsync(
            maxConcurrencyCount: taskLimit,
            mapPriority: .userInitiated,
            mapBlock: { [unowned self] (image, index) in
                return try await self.processImage(image,
                                                   with: engine,
                                                   indexed: index,
                                                   config: assetWriterConfig,
                                                   context: ciContext)
            },
            serialPerformBlock: { [unowned self] sample in
                try await assetWriterConfig.inputAdaptor.assetWriterInput.waitUntilReadyForMoreMediaData()

                if !assetWriterConfig.inputAdaptor.append(sample.buffer, withPresentationTime: sample.time) {
                    PRLogger.imageProcessing.error("Frame was not appended to video!")
                }

                sample.buffer.unlock()

                await self.advanceProcessingProgress(by: 1.0 / Double(count))
            }
        )
        
        assetWriterConfig.inputAdaptor.assetWriterInput.markAsFinished()
        await assetWriterConfig.assetWriter.finishWriting()
        
        let writerStatus = assetWriterConfig.assetWriter.status
        if writerStatus != .completed {
            let error = assetWriterConfig.assetWriter.error ?? MergeError.unknown
            PRLogger.imageProcessing.error("Status is not completed after finishing writing! [\(writerStatus.rawValue)] [error: \(error)]")
        }
        
        self.state.value = .finished
        return ProgressVideo(videoId: assetWriterConfig.videoId,
                             url: assetWriterConfig.outputUrl,
                             resolution: assetWriterConfig.userSettings.extents)
    }
    
    // MARK: - Private functions
    private func setState(to state: State) {
        self.state.value = state
    }
    
    private func advanceProcessingProgress(by value: Double) {
        guard case let .working(progress) = self.state.value else {
            PRLogger.imageProcessing.warning("Cannot advance processing progress without `.working` being the current state!")
            return
        }
        
        self.state.value = .working(progress: min(1.0, progress + value))
    }
    
    private func processImage<ConversionEngine: PhotoConversionEngine>(
        _ image: ConversionEngine.Input,
        with engine: ConversionEngine,
        indexed index: Int,
        config: VideoAssetWriterConfiguration,
        context: CIContext
    ) async throws -> Sample {
        var data: Data
        do {
            data = try await engine.convertInput(image)
        } catch let error {
            PRLogger.imageProcessing.error("Image could not be converted to `Data`! [\(error)]")
            throw MergeError.dataConversionFailure
        }
        
        guard let ciImage = CIImage(data: data, options: [.applyOrientationProperty: true]) else {
            PRLogger.imageProcessing.error("Could not create CIImage from Data!")
            throw MergeError.ciImageCreationFailure
        }
        
        guard let pixelBufferPool = config.inputAdaptor.pixelBufferPool else {
            PRLogger.imageProcessing.error("PixelBufferPool is unexpectedly nil!")
            throw MergeError.missingPixelBufferPool
        }
        
        var pixelBuffer: CVPixelBuffer!
        let success = CVPixelBufferPoolCreatePixelBuffer(nil, pixelBufferPool, &pixelBuffer)
        if success != kCVReturnSuccess {
            PRLogger.imageProcessing.error("Failed to create pixel buffer! \(success)")
        }
        
        let scaledToFitImage = ciImage
            .scaleToFitInContainerOfSize(config.userSettings.extents)
            .positionInContainerOfSize(config.userSettings.extents)
        
        PRLogger.imageProcessing.debug("resizedImage extent: \(scaledToFitImage.extent.debugDescription)")
        
        pixelBuffer.lockAndClear(with: config.userSettings.backgroundColorComponents)
        
        context.clearCaches() // Removes ciContext caches. Important!
        context.render(scaledToFitImage,
                       to: pixelBuffer,
                       bounds: scaledToFitImage.extent,
                       colorSpace: CGColorSpaceCreateDeviceRGB()) // Not setting the color space produces a dark image!!!
        
        let time = CMTime(value: Int64(index), timescale: 5)
        return Sample(index: index, time: time, buffer: pixelBuffer)
    }
    
    // MARK: - Typealias Sample
    private typealias Sample = (
        index: Int,
        time: CMTime,
        buffer: CVPixelBuffer
    )
}


