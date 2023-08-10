//
//  ProcessInfo+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 10..
//

import Foundation

extension ProcessInfo {
    class var recommendedMaximumConcurrency: Int {
        switch Task.currentPriority {
        case .high, .userInitiated:
            return max(ProcessInfo().activeProcessorCount - 2, 1)
            
        default:
            return max(ProcessInfo().activeProcessorCount - 3, 1)
        }
    }
}
