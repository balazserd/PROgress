//
//  NSNotification.Name+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/04/2024.
//

import Foundation

extension NSNotification.Name {
    static let didCreateNewProgressVideo: Self = .init("com.ebuniapps.PROgress.didCreateNewProgressVideo")
    static let didUpdateProgressVideoProperties: Self = .init("com.ebuniapps.PROgress.didUpdateProgressVideoProperties")
    static let didRemoveProgressVideos: Self = .init("com.ebuniapps.PROgress.didRemoveProgressVideos")
}
