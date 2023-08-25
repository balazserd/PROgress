//
//  Photos+Sendable.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 25..
//

import Foundation
import Photos
import PhotosUI
import SwiftUI

// PHxxx types are Sendable based on documentation, but they don't seem to be that way here...
extension PHAsset: @unchecked Sendable { }
extension PHAssetCollection: @unchecked Sendable { }
extension PHFetchResult: @unchecked Sendable { }

// I asked about this on the forums: https://developer.apple.com/forums/thread/736359
extension PhotosPickerItem: @unchecked Sendable { }
