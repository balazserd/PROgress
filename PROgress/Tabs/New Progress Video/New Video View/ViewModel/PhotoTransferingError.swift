//
//  PhotoTransferingError.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 08..
//

import Foundation

enum PhotoTransferingError: Error {
    /// The file cannot be imported as a `UIImage`.
    case invalidUIImage
}
