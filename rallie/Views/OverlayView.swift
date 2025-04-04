//
//  OverlayView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct OverlayView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            // Adjust position + slimming
            let topY = height * 0.55         // moved further down
            let bottomY = height * 0.85      // moved further down
            let topInset: CGFloat = width * 0.25   // slimmer top
            let bottomInset: CGFloat = width * 0.15  // slimmer bottom

            let topLeft = CGPoint(x: topInset, y: topY)
            let topRight = CGPoint(x: width - topInset, y: topY)
            let bottomRight = CGPoint(x: width - bottomInset, y: bottomY)
            let bottomLeft = CGPoint(x: bottomInset, y: bottomY)

            Path { path in
                path.move(to: topLeft)
                path.addLine(to: topRight)
                path.addLine(to: bottomRight)
                path.addLine(to: bottomLeft)
                path.closeSubpath()
            }
            .stroke(Color.red, lineWidth: 4)
        }
        .ignoresSafeArea()
    }
}

