//
//  CourtOverlayView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/2/25.
//

import SwiftUI

struct CourtOverlayView: View {
    let courtLines: [LineSegment]

    var body: some View {
        Canvas { context, size in
            for segment in courtLines {
                let path = Path { path in
                    path.move(to: segment.start)
                    path.addLine(to: segment.end)
                }
                context.stroke(path, with: .color(.white.opacity(0.3)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

// Helper structure to represent a line between two points
struct LineSegment {
    let start: CGPoint
    let end: CGPoint
}
