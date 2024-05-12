//
//  DateFormatter+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 12/05/2024.
//

import Foundation

extension DateComponentsFormatter {
    static let videoDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        
        return formatter
    }()
}

extension DateFormatter {
    static let videoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        
        return formatter
    }()
}
