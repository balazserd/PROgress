//
//  PGLogger.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 03..
//

import Foundation
import os

/// The collection of `Logger` instances the app uses.
///
/// - Important: Always use the logger corresponding to the correct category for logging events.
enum PRLogger {
    static let app = Logger(subsystem: "com.ebuniapps.PROgress",
                            category: "app")
    static let imageProcessing = Logger(subsystem: "com.ebuniapps.PROgress",
                                        category: "imageProcessing")
    
    static let photoLibraryManagement = Logger(subsystem: "com.ebuniapps.PROgress",
                                               category: "photoLibraryManagement")
    
    static let photoConversion = Logger(subsystem: "com.ebuniapps.PROgress",
                                        category: "photoConversion")
}
