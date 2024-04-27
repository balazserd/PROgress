//
//  Text+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 27/03/2024.
//

import Foundation
import SwiftUI

extension Text {
    func tableRowDataStyle() -> some View {
        self.font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}
