//
//  PHImageRequestOptions+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 07/05/2024.
//

import Foundation
import Photos

extension PHImageRequestOptions {
    static var thumbnail: Self {
        let requestOptions = Self()
        requestOptions.resizeMode = .fast
        requestOptions.version = .current
        requestOptions.isNetworkAccessAllowed = true
        
        return requestOptions
    }
    
    static var detailed: Self {
        let requestOptions = Self()
        requestOptions.resizeMode = .exact
        requestOptions.version = .current
        requestOptions.isNetworkAccessAllowed = true
        
        return requestOptions
    }
}
