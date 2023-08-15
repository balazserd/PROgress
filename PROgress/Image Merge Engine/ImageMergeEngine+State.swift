//
//  ImageMergeEngine+State.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation

extension ImageMergeEngine {
    enum State: Equatable {
        case idle
        case working(progress: Double)
        case finished
        
        var isWorking: Bool {
            if case .working = self {
                return true
            } else {
                return false
            }
        }
    }
}
