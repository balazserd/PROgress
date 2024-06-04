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
@preconcurrency import AVFoundation
import EBUniAppsKit
import Combine
import CoreImage.CIFilterBuiltins

actor ImageMergeEngine {
    static let backgroundTaskName = "com.ebuniapps.PROgress-imageMergeTask"
    
    nonisolated let state = CurrentValueSubject<State, Never>(.idle)
    
    // MARK: -  Operation-private variables
    private var watermarkImage: CIImage?
    
    // MARK: - Operations
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
        _ images: [ConversionEngine.Input],
        by engine: ConversionEngine,
        options: MergeOptions
    ) async throws -> ProgressVideo {
        self.watermarkImage = nil // Always reset the watermark between merges.
        
        let indexedImages = images.enumerated().map { ($1, $0) }
        
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
        let reusableContext = CIContext()
        
        try await indexedImages.mapConcurrentlyThenPerformSeriallyAsync(
            maxConcurrencyCount: taskLimit,
            mapPriority: .userInitiated,
            mapBlock: { [unowned self] (image, index) in
                return try await self.processImage(image,
                                                   with: engine,
                                                   indexed: index,
                                                   config: assetWriterConfig,
                                                   context: reusableContext)
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
        
        var pixelBuffer: CVPixelBuffer!
        let success = CVPixelBufferPoolCreatePixelBuffer(nil, config.inputAdaptor.pixelBufferPool!, &pixelBuffer)
        if success != kCVReturnSuccess {
            PRLogger.imageProcessing.error("Failed to create pixel buffer! \(success)")
            throw MergeError.pixelBufferCreationError
        }
        
        let scaledToFitImage = ciImage
            .scaleToFitInContainerOfSize(config.userSettings.extents)
            .positionInContainerOfSize(config.userSettings.extents)
        
        PRLogger.imageProcessing.debug("resizedImage extent: \(scaledToFitImage.extent.debugDescription)")
        
        pixelBuffer.lock()
        
        let base = CIImage(color: .white)
        let backgroundColor = CIColor(argbComponents: config.userSettings.backgroundColorComponentsARGB)
        let background = CIImage(color: backgroundColor)
        
        var finalImage = scaledToFitImage // Video frame.
            .composited(over: background) // Actual background color.
            .composited(over: base) // Overwrites base black background, allowing for background colors with alpha.
        
        if !config.userSettings.hideLogo {
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            
            if self.watermarkImage == nil {
                let videoSize = CGSize(width: width, height: height)
                self.watermarkImage = try self.createWatermarkImage(size: videoSize,
                                                                    backgroundColor: backgroundColor)
            }
            
            finalImage = self.watermarkImage!
                .composited(over: finalImage)
                .clamped(to: CGRect(origin: .zero, size: .init(width: width, height: height)))
        }
        
        context.clearCaches() // Removes CIContext caches. Important!
        context.render(finalImage,
                       to: pixelBuffer,
                       bounds: finalImage.extent,
                       colorSpace: CGColorSpace(name: CGColorSpace.sRGB)) // Not setting the color space produces a dark image.

        let time = CMTime(value: Int64(index) * Int64(config.userSettings.timeBetweenFrames / 0.05),
                          timescale: 20)
        
        return Sample(index: index, time: time, buffer: pixelBuffer)
    }
    
    private static let watermarkRatio = 0.06
    private static let watermarkPadding = 12.5
//    private static let watermarkIconSize = 25
    
    private func createWatermarkImage(size: CGSize, backgroundColor: CIColor) throws -> CIImage {
        // Required size
        let watermarkIconRequiredSize = CGSize(width: min(size.height, size.width) * Self.watermarkRatio,
                                               height: min(size.height, size.width) * Self.watermarkRatio)
//        let watermarkIconRequiredSize = CGSize(width: Self.watermarkIconSize, height: Self.watermarkIconSize)
        
        // Watermark Icon
        guard
            let watermarkIconUrl = Bundle.main.url(forResource: "PROgressWatermarkIcon", withExtension: "tiff"),
            let watermarkIconOriginalSize = CIImage(contentsOf: watermarkIconUrl)
        else {
            PRLogger.imageProcessing.error("Watermarking error, bundle png corrupted or missing!")
            throw WatermarkingError.watermarkIconMissingInBundle
        }
        
        let watermarkIconFinalSize = watermarkIconOriginalSize
            .transformed(by: CGAffineTransform(
                scaleX: watermarkIconRequiredSize.width / watermarkIconOriginalSize.extent.width,
                y: watermarkIconRequiredSize.height / watermarkIconOriginalSize.extent.height)
            )
            .transformed(by: CGAffineTransform(
                translationX: size.width - Self.watermarkPadding - watermarkIconRequiredSize.width,
                y: Self.watermarkPadding)
            )
        
        // Watermark Text
        let watermarkTextFilter = CIFilter.attributedTextImageGenerator()
        watermarkTextFilter.text = NSAttributedString(string: "Made with PROgress")
        watermarkTextFilter.scaleFactor = 2
        watermarkTextFilter.padding = 5
        
        guard let watermarkTextImage = watermarkTextFilter.outputImage else {
            PRLogger.imageProcessing.error("Watermarking error, text filter cannot be built!")
            throw WatermarkingError.watermarkTextFilterFailure
        }
        
        let watermarkTextFinalSizeScaling = watermarkIconRequiredSize.height / watermarkTextImage.extent.height
        let watermarkTextImageResized = watermarkTextImage
            .transformed(by: CGAffineTransform(
                scaleX: watermarkTextFinalSizeScaling,
                y: watermarkTextFinalSizeScaling)
            )
        let watermarkTextImageResizedAndPositioned = watermarkTextImageResized
            .transformed(by: CGAffineTransform(
                translationX: size.width - Self.watermarkPadding - watermarkIconRequiredSize.width - 10 - watermarkTextImageResized.extent.width,
                y: Self.watermarkPadding)
            )
        
        // Watermark Background
        let watermarkBackgroundFilter = CIFilter.roundedRectangleGenerator()
        watermarkBackgroundFilter.color = CIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        watermarkBackgroundFilter.extent = CGRect(x: 0, y: 0,
                                                  width: size.width,
                                                  height: Self.watermarkPadding * 2 + watermarkIconRequiredSize.height)
        watermarkBackgroundFilter.radius = 0
        guard let watermarkBackgroundImage = watermarkBackgroundFilter.outputImage else {
            PRLogger.imageProcessing.error("Watermarking error, background filter cannot be built!")
            throw WatermarkingError.watermarkBackgroundFilterFailure
        }
        
        return watermarkTextImageResizedAndPositioned
            .composited(over: watermarkIconFinalSize)
            .composited(over: watermarkBackgroundImage)
            .composited(over: CIImage(color: .clear))
    }
    
    // MARK: - Typealias Sample
    private struct Sample: @unchecked Sendable {
        var index: Int
        var time: CMTime
        var buffer: CVPixelBuffer // sample should only be accessed on a serial queue to be Sendable.
    }
}


