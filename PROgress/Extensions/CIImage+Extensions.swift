//
//  CIImage+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import CoreImage

extension CIImage {
    /// Transforms an image to fit in a container size.
    func scaleToFitInContainerOfSize(_ size: CGSize) -> CIImage {
        
        let maximumHeightScale = size.height / self.extent.height
        let maximumWidthScale = size.width / self.extent.width
        
        let finalScaleSize = min(maximumWidthScale, maximumHeightScale)
        
        return self.transformed(by: CGAffineTransform(scaleX: finalScaleSize,
                                                      y: finalScaleSize))
    }
    
    /// Returns the appropriate origin to center an image in a **larger** container size.
    func positionInContainerOfSize(_ size: CGSize) -> CIImage {
        return self.transformed(by: CGAffineTransform(translationX: (size.width - self.extent.width) / 2,
                                                      y: (size.height - self.extent.height) / 2))
    }
}
