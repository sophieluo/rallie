//
//  OverlayHelper.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/12/25.
//

import SwiftUI

struct OverlayHelper {
    static func computeTrapezoid(in geometry: GeometryProxy) -> [CGPoint] {
        computeTrapezoid(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
    }

    static func computeTrapezoid(screenWidth: CGFloat, screenHeight: CGFloat) -> [CGPoint] {
        let topY = screenHeight * 0.55
        let bottomY = screenHeight * 0.85
        let topInset = screenWidth * 0.25
        let bottomInset = screenWidth * 0.15

        return [
            CGPoint(x: bottomInset, y: bottomY),         // near-left
            CGPoint(x: screenWidth - bottomInset, y: bottomY), // near-right
            CGPoint(x: screenWidth - topInset, y: topY),  // far-right
            CGPoint(x: topInset, y: topY)                // far-left
        ]
    }
}

