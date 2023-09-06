//
//  ImageMergeEngine+VideoAssetWriterConfiguration.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 13..
//

import Foundation
import AVFoundation

/// A configuration object that contains information necessary to produce progress videos with ``ImageMergeEngine`` by utilizing an ``AVFoundation/AVAssetWriter``.
class VideoAssetWriterConfiguration: @unchecked Sendable {
    let assetWriter: AVAssetWriter
    let inputAdaptor: AVAssetWriterInputPixelBufferAdaptor
    let outputUrl: URL!
    let videoId: UUID
    let userSettings: VideoProcessingUserSettings
    
    /// Initializes a configuration object for the specified resolution.
    ///
    /// - Throws: An underlying AVFoundation error type or one of the cases in the ``VideoAssetWriterConfigurationError`` enum.
    init(settings: VideoProcessingUserSettings) throws {
        self.userSettings = settings
        self.videoId = UUID()
        
        self.outputUrl = FileManager()
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(videoId.uuidString, conformingTo: .quickTimeMovie)
        
        guard outputUrl != nil else {
            throw VideoAssetWriterConfigurationError.couldNotCreateFileURL
        }
        
        assetWriter = try AVAssetWriter(url: self.outputUrl, fileType: .mov)
        
        let outputSettings: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.hevcWithAlpha,
                                             AVVideoWidthKey: NSNumber(value: Int(settings.extentX)),
                                            AVVideoHeightKey: NSNumber(value: Int(settings.extentY))]
        guard assetWriter.canApply(outputSettings: outputSettings, forMediaType: .video) else {
            throw VideoAssetWriterConfigurationError.cannotApplyOutputSettingsForMediaType
        }
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        guard assetWriter.canAdd(input) else {
            throw VideoAssetWriterConfigurationError.cannotAddInput
        }
        assetWriter.add(input)
        
        inputAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes:
                [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB)]
        )
    }
    
    enum VideoAssetWriterConfigurationError: Error {
        case couldNotCreateFileURL
        case cannotApplyOutputSettingsForMediaType
        case cannotAddInput
    }
}
