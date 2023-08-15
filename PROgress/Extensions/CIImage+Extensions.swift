//
//  CIImage+Extensions.swift
//  PROgress
//
//  Created by Balázs Erdész on 2023. 08. 15..
//

import Foundation
import CoreImage

extension CIImage {
    /// Transforms an image to fit in a **larger** container size.
    ///
    /// - Important: This method assumes that `size` is not smaller in either dimensions than `CIImage.extents`.
    func scaleUpToFitInContainerOfSize(_ size: CGSize) -> CIImage {
        precondition(size.width >= self.extent.width && size.height >= self.extent.height,
                     "The specified size is smaller than the CIImage's current size!")
        
        let maximumHeightScale = size.height / self.extent.height
        let maximumWidthScale = size.width / self.extent.width
        
        let finalScaleSize = min(maximumWidthScale, maximumHeightScale)
        
        return self.transformed(by: CGAffineTransform(scaleX: finalScaleSize,
                                                      y: finalScaleSize))
    }
    
    /// Returns the appropriate origin to center an image in a **larger** container size.
    ///
    /// - Important: This method assumes that `size` is not smaller in either dimensions than `CIImage.extents`.
    func positionInContainerOfSize(_ size: CGSize) -> CIImage {
        return self.transformed(by: CGAffineTransform(translationX: (size.width - self.extent.width) / 2,
                                                      y: (size.height - self.extent.height) / 2))
    }
}
