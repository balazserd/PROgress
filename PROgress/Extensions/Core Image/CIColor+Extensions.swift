//
//  CIColor+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 09. 06..
//

import Foundation
import CoreImage

extension CIColor {
    convenience init(argbComponents: [UInt8]) {
        self.init(red: CGFloat(argbComponents[1]) / 255,
                  green: CGFloat(argbComponents[2]) / 255,
                  blue: CGFloat(argbComponents[3]) / 255,
                  alpha: CGFloat(argbComponents[0]) / 255)
    }
}
