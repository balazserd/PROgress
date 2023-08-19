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

class ImageMergeEngine {
    @MainActor var state = CurrentValueSubject<State, Never>(.idle)
    
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
        
        let assetWriterConfig = try VideoAssetWriterConfiguration(resolution: options.size)
        guard assetWriterConfig.assetWriter.startWriting() else {
            let error = assetWriterConfig.assetWriter.error
            let status = assetWriterConfig.assetWriter.status.rawValue
            
            PRLogger.imageProcessing.error("Failed to start asset writing! [status: \(status)] [error: \(error)]")
            
            throw MergeError.assetWriterStartFailure
        }
        
        await state.send(.working(progress: 0.0))
        
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
                while !assetWriterConfig.inputAdaptor.assetWriterInput.isReadyForMoreMediaData {
                    try await Task.sleep(for: .milliseconds(100))
                }

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
        
        await self.setState(to: .finished)
        return ProgressVideo(videoId: assetWriterConfig.videoId,
                             url: assetWriterConfig.outputUrl,
                             resolution: assetWriterConfig.resolution)
    }
    
    // MARK: - Private functions
    @MainActor
    private func setState(to state: State) {
        self.state.value = state
    }
    
    @MainActor
    private func advanceProcessingProgress(by value: Double) {
        guard case let .working(progress) = self.state.value else {
            PRLogger.imageProcessing.warning("Cannot advance processing progress without `.working` being the current state!")
            return
        }
        
        self.setState(to: .working(progress: min(1.0, progress + value)))
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
        
        guard let ciImage = CIImage(data: data) else {
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
            .scaleToFitInContainerOfSize(config.resolution)
            .positionInContainerOfSize(config.resolution)
        
        PRLogger.imageProcessing.debug("resizedImage extent: \(scaledToFitImage.extent.debugDescription)")
        
        pixelBuffer.lockAndClear()
        
        context.clearCaches() // Removes ciContext caches. Important!
        context.render(scaledToFitImage,
                       to: pixelBuffer,
                       bounds: scaledToFitImage.extent,
                       colorSpace: nil)
        
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


