//
//  OverlayView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct OverlayView {
    static func redTrapezoid(in geometry: GeometryProxy) -> [CGPoint] {
        let width = geometry.size.width
        let height = geometry.size.height

        let topY = height * 0.55
        let bottomY = height * 0.85
        let topInset = width * 0.25
        let bottomInset = width * 0.15

        return [
            CGPoint(x: bottomInset, y: bottomY),         // near-left
            CGPoint(x: width - bottomInset, y: bottomY), // near-right
            CGPoint(x: width - topInset, y: topY),       // far-right
            CGPoint(x: topInset, y: topY)                // far-left
        ]
    }
}


