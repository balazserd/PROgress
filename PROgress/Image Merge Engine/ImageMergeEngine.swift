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
    
    func mergeImages(_ images: [PhotosPickerItem], options: MergeOptions) async throws -> ProgressVideo {
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
        
        try await images.mapConcurrentlyThenPerformSeriallyAsync(
            maxConcurrencyCount: taskLimit,
            mapPriority: .userInitiated,
            mapBlock: { image in
                return try await self.processImage(image,
                                                   indexed: images.firstIndex(of: image)!,
                                                   by: assetWriterConfig,
                                                   in: ciContext)
            },
            serialPerformBlock: { sample in
                await assetWriterConfig.inputAdaptor.assetWriterInput.waitUntilReadyForMoreMediaData()
                
                // TODO investigate possible issue when smaller image has background of previous image (pixelbufferpool not cleared between uses?)
                if !assetWriterConfig.inputAdaptor.append(sample.buffer, withPresentationTime: sample.time) {
                    PRLogger.imageProcessing.error("Frame was not appended to video!")
                }
                
                sample.buffer.unlock()
                
                await self.advanceProcessingProgress(by: 1.0 / Double(images.count))
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
    
    private func processImage(_ image: PhotosPickerItem,
                              indexed index: Int,
                              by config: VideoAssetWriterConfiguration,
                              in context: CIContext) async throws -> Sample {
        guard let data = try await image.loadTransferable(type: Data.self) else {
            PRLogger.imageProcessing.error("Image could not be converted to `Data`!")
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
            .scaleUpToFitInContainerOfSize(config.resolution)
            .positionInContainerOfSize(config.resolution)
        
        print("resizedImage extent: \(scaledToFitImage.extent)")
        
        pixelBuffer.lockAndClear()
        
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


