//
//  VideoProcessingUserSettings.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 01..
//

import Foundation
import SwiftUI

struct VideoProcessingUserSettings: Sendable {
    var timeBetweenFrames: Double
    var resolution: Resolution! {
        didSet {
            guard oldValue != resolution else { return }
            
            switch resolution {
            case .customWidthPreservedAspectRatio:
                customExtentAxis = .horizontal
                aspectRatio = Double(extentX) / Double(extentY)
                
            case .custom:
                customExtentAxis = nil
                aspectRatio = nil
                
            default:
                extentX = min(extentX, resolution.maxExtentLength!)
                extentY = min(extentY, resolution.maxExtentLength!)
            }
        }
    }
    
    var extents: CGSize { CGSize(width: extentX, height: extentY) }
    
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
    
    private(set) var aspectRatio: Double!
    
    init(timeBetweenFrames: Double = 0.2,
         resolution: Resolution = .medium,
         extentX: Double = 640,
         extentY: Double = 320,
         backgroundColor: Color = .white,
         customExtentAxis: Axis? = .horizontal) {
        self.timeBetweenFrames = timeBetweenFrames
        self.extentX = extentX
        self.extentY = extentY
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
}
