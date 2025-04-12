//
//  CourtLayout.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

// MARK: - CourtLayout.swift
import CoreGraphics

struct CourtLayout {
    static let screenWidth: CGFloat = 844   // landscape iPhone 13
    static let screenHeight: CGFloat = 390

    static func referenceImagePoints(for screenSize: CGSize) -> [CGPoint] {
        return OverlayHelper.computeTrapezoid(
            screenWidth: screenSize.width,
            screenHeight: screenSize.height
        )
    }

    static let referenceCourtPoints: [CGPoint] = [
        CGPoint(x: 0, y: 0),       // near-left
        CGPoint(x: 8.23, y: 0),    // near-right
        CGPoint(x: 8.23, y: 5.49), // far-right
        CGPoint(x: 0, y: 5.49)     // far-left
    ]
}

