//
//  CourtLayout.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import CoreGraphics

struct CourtLayout {
    static let referencePoints: [CGPoint] = [
        CGPoint(x: 0, y: 0),     // near left service line (court-space)
        CGPoint(x: 8, y: 0),     // near right service line
        CGPoint(x: 0, y: 12),    // far left baseline
        CGPoint(x: 8, y: 12)     // far right baseline
    ]
}
