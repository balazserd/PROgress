//
//  VideoProcessingUserSettings.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 01..
//

import Foundation
import SwiftUI

struct VideoProcessingUserSettings: Sendable {
    private let maxPhotoExtentX: CGFloat
    private let maxPhotoExtentY: CGFloat
    
    var hideLogo: Bool = false
    var addBeforeAfterFinalImage: Bool = false
    
    var timeBetweenFrames: Double
    var resolution: Resolution! {
        didSet {
            guard oldValue != resolution else { return }
            
            switch resolution {
            case .customWidthPreservedAspectRatio:
                customExtentAxis = .horizontal
                shape = .automatic
                aspectRatio = Double(extentX) / Double(extentY)
                
            case .custom:
                customExtentAxis = nil
                shape = .automatic
                aspectRatio = nil
                
            default:
                extentX = min(maxPhotoExtentX, resolution.maxExtentLength!)
                extentY = min(maxPhotoExtentY, resolution.maxExtentLength!)
            }
        }
    }
    
    var shape: Shape = .automatic
    
    var extents: CGSize {
        let defaultExtents = CGSize(width: extentX, height: extentY)
        guard shape != .automatic else {
            return defaultExtents
        }
        
        let aspectRatioModifier = shape.aspectRatio!
        
        switch extentX / extentY {
        case let extentRatio where extentRatio > aspectRatioModifier:
            return .init(width: extentY * aspectRatioModifier, height: extentY)
            
        case let extentRatio where extentRatio <= aspectRatioModifier:
            return .init(width: extentX, height: extentX / aspectRatioModifier)
            
        default:
            return defaultExtents
        }
    }
    
    var extentX: Double {
        didSet {
            guard customExtentAxis == .horizontal else { return }
            extentY = extentX / aspectRatio
        }
    }
    
    var extentY: Double {
        didSet {
            guard customExtentAxis == .vertical else { return }
            extentX = extentY * aspectRatio
        }
    }
    
    var backgroundColor: Color = .white {
        didSet {
            if  let rgbCgColor = UIColor(backgroundColor)
                    .cgColor
                    .converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
                rgbCgColor.numberOfComponents == 4,
                let components = rgbCgColor.components
            {
                var rgbaCompontents = components.map { UInt8(CGFloat(255) * $0) }
                let alpha = rgbaCompontents.removeLast()
                rgbaCompontents.insert(alpha, at: 0)
                
                backgroundColorComponentsARGB = rgbaCompontents
            } else {
                PRLogger.imageProcessing.notice("Will use fallback settings for background color.")
                backgroundColorComponentsARGB = [0xFF, 0xFF, 0xFF, 0xFF]
            }
        }
    }
    
    /// The background color's components as hex values.
    ///
    /// The order of components is as following: alpha, red, green, blue.
    private(set) var backgroundColorComponentsARGB: [UInt8]!
    
    var customExtentAxis: Axis?
    
    var videoName: String = "New Progress Video"
    
    private(set) var aspectRatio: Double!
    
    init(timeBetweenFrames: Double = 0.2,
         resolution: Resolution = .medium,
         maxPhotoExtentX: Double = 640,
         maxPhotoExtentY: Double = 320,
         backgroundColor: Color = .white,
         customExtentAxis: Axis? = .horizontal) {
        self.timeBetweenFrames = timeBetweenFrames
        self.maxPhotoExtentX = maxPhotoExtentX
        self.maxPhotoExtentY = maxPhotoExtentY
        self.extentX = maxPhotoExtentX
        self.extentY = maxPhotoExtentY
        defer {
            self.backgroundColor = backgroundColor
            self.resolution = resolution
        }
        
        self.customExtentAxis = customExtentAxis
        if customExtentAxis != nil {
            aspectRatio = extentX / extentY
        }
    }
    
    // MARK: - Resolution enumeration
    enum Resolution: String, CaseIterable {
        case tiny = "Tiny"
        case low = "Low"
        case medium = "Medium (HD)"
        case high = "High (Full HD)"
        case ultra = "Ultra (Quad HD)"
        case customWidthPreservedAspectRatio = "Custom (preserve aspect ratio)"
        case custom = "Custom (both extents)"
        
        var displayName: String { self.rawValue }
        
        var shortName: String {
            switch self {
            case .custom: return "Custom (free)"
            case .customWidthPreservedAspectRatio: return "Custom (aspect fixed)"
            default: return self.displayName
            }
        }
        
        var extraShortName: String {
            switch self {
            case .tiny: return "Tiny"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .ultra: return "Ultra"
            case .custom, .customWidthPreservedAspectRatio: return "Custom"
            }
        }
        
        var maxExtentLength: Double? {
            switch self {
            case .tiny: return 480
            case .low: return 800
            case .medium: return 1280
            case .high: return 1920
            case .ultra: return 2560
            default: return nil
            }
        }
        
        var isFreeTierOption: Bool {
            switch self {
            case .tiny, .low, .medium: return true
            default: return false
            }
        }
    }
    
    // MARK: - Shape
    enum Shape: String, CaseIterable {
        case automatic = "Automatic"
        case reel = "Reel"
        case video_4_3 = "4:3 Video"
        case video_16_9 = "16:9 Video"
        case video_1_1 = "Square Video"
        
        var complimentaryText: String {
            switch self {
            case .automatic:
                "The video will expand to fit the largest extent in both axis, and place all other images centered."
            case .reel:
                "The video will be shaped like social media reels (larger vertical axis, shorter horizontal)."
            case .video_4_3:
                "The video will have a standard 4:3 ratio."
            case .video_16_9:
                "The video will have a standard 16:9 ratio."
            case .video_1_1:
                "The video shape will be a square."
            }
        }
        
        var aspectRatio: Double? {
            switch self {
            case .automatic:    return nil
            case .reel:         return 1080 / 2160
            case .video_4_3:    return 4 / 3
            case .video_16_9:   return 16 / 9
            case .video_1_1:    return 1
            }
        }
    }
}
