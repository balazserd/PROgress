//
//  Axis+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 01..
//

import Foundation
import SwiftUI

extension Axis {
    var displayName: String {
        switch self {
        case .horizontal: return "Width"
        case .vertical: return "Height"
        }
    }
}
