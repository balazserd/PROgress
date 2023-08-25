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

extension PHAsset: @unchecked Sendable { }
extension PHAssetCollection: @unchecked Sendable { }
extension PHFetchResult: @unchecked Sendable { }

extension PhotosPickerItem: @unchecked Sendable { }
