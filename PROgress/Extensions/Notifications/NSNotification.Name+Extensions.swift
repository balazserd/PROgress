//
//  NSNotification.Name+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/04/2024.
//

import Foundation

extension NSNotification.Name {
    static let didCreateNewProgressVideo: NSNotification.Name = .init("com.ebuniapps.PROgress.didCreateNewProgressVideo")
    static let didRemoveProgressVideos: NSNotification.Name = .init("com.ebuniapps.PROgress.didRemoveProgressVideos")
}
