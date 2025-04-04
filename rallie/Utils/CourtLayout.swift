//
//  CourtLayout.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

// MARK: - CourtLayout.swift

import CoreGraphics

struct CourtLayout {
    /// Pixel coordinates on screen (based on red trapezoid overlay in CameraView)
    static let referenceImagePoints: [CGPoint] = [
        CGPoint(x: 120, y: 450), // near left service line
        CGPoint(x: 260, y: 450), // near right service line
        CGPoint(x: 140, y: 150), // far left baseline
        CGPoint(x: 240, y: 150)  // far right baseline
    ]

    /// Court coordinates in meters (corresponding real-world court space)
    static let referenceCourtPoints: [CGPoint] = [
        CGPoint(x: 0, y: 0),       // near left service line
        CGPoint(x: 8.23, y: 0),    // near right service line
        CGPoint(x: 0, y: 5.49),    // far left baseline
        CGPoint(x: 8.23, y: 5.49)  // far right baseline
    ]
}
