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
    
    func mergeImages(_ images: [PhotosPickerItem]) async throws -> ProgressVideo {
        let ciContext = CIContext()
        
        let assetWriterConfig = try AssetWriterConfiguration()
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
                
                assetWriterConfig.inputAdaptor.append(sample.buffer,
                                                      withPresentationTime: sample.time)
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
        return ProgressVideo(url: assetWriterConfig.outputUrl)
    }
    
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
                              by config: AssetWriterConfiguration,
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
        
        context.render(ciImage, to: pixelBuffer)
        
        let time = CMTime(value: Int64(index+1), timescale: 5)
        return Sample(index: index, time: time, buffer: pixelBuffer)
    }
    
    enum State: Equatable {
        case idle
        case working(progress: Double)
        case finished
        
        var isWorking: Bool {
            if case .working = self {
                return true
            } else {
                return false
            }
        }
    }
    
    enum MergeError: Error {
        case unknown
        case dataConversionFailure
        case taskNotFound
        case assetWriterStartFailure
        case missingPixelBufferPool
        case missingSample
        case ciImageCreationFailure
    }
    
    private class AssetWriterConfiguration {
        let assetWriter: AVAssetWriter
        let inputAdaptor: AVAssetWriterInputPixelBufferAdaptor
        let outputUrl: URL!
        
        init() throws {
            outputUrl = FileManager()
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first?
                .appendingPathComponent(UUID().uuidString, conformingTo: .quickTimeMovie)
            
            guard outputUrl != nil else {
                throw AssetWriterConfigurationError.couldNotCreateFileURL
            }
            
            assetWriter = try AVAssetWriter(url: self.outputUrl, fileType: .mov)
            
            let outputSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.h264,
                                                 AVVideoWidthKey: NSNumber(value: 640),
                                                AVVideoHeightKey: NSNumber(value: 640)]
            guard assetWriter.canApply(outputSettings: outputSettings, forMediaType: .video) else {
                throw AssetWriterConfigurationError.cannotApplyOutputSettingsForMediaType
            }
            
            let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
            guard assetWriter.canAdd(input) else {
                throw AssetWriterConfigurationError.cannotAddInput
            }
            assetWriter.add(input)
            
            inputAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: input,
                sourcePixelBufferAttributes:
                    [kCVPixelBufferPixelFormatTypeKey as String: Int(kCMPixelFormat_32BGRA)]
            )
        }
        
        enum AssetWriterConfigurationError: Error {
            case couldNotCreateFileURL
            case cannotApplyOutputSettingsForMediaType
            case cannotAddInput
        }
    }
    
    private typealias Sample = (
        index: Int,
        time: CMTime,
        buffer: CVPixelBuffer
    )
}

extension AVAssetWriterInput {
    func waitUntilReadyForMoreMediaData() async {
        if self.isReadyForMoreMediaData {
            return
        }
        
        PRLogger.imageProcessing.debug("Not ready for more media data! Waiting...")
        
        let readinessChanged = self.publisher(for: \.isReadyForMoreMediaData,
                                              options: [.initial, .new])
        for await ready in readinessChanged.values {
            guard ready else { continue }
            
            PRLogger.imageProcessing.debug("Became ready for more media data.")
            
            return
        }
    }
}
