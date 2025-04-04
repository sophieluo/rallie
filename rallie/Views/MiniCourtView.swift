//
//  MiniCourtView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/3/25.
//

import SwiftUI

struct MiniCourtView: View {
    let projectedPoint: CGPoint?  // 🟢 The user tap (mapped via homography)

    // Constants for singles half-court (in meters)
    let courtWidth: CGFloat = 8.23
    let courtHeight: CGFloat = 5.49

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / courtWidth
            let scaleY = geo.size.height / courtHeight

            ZStack {
                // 🏟️ Draw court lines
                Path { path in
                    // Outer boundary
                    path.addRect(CGRect(x: 0, y: 0,
                                        width: courtWidth * scaleX,
                                        height: courtHeight * scaleY))

                    // Center service line
                    let centerX = (courtWidth / 2) * scaleX
                    path.move(to: CGPoint(x: centerX, y: 0))
                    path.addLine(to: CGPoint(x: centerX, y: courtHeight * scaleY))
                }
                .stroke(Color.white, lineWidth: 1)

                // 🟢 Marker for tap (if available)
                if let pt = projectedPoint {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(x: pt.x * scaleX, y: pt.y * scaleY)
                }
            }
        }
        .aspectRatio(courtWidth / courtHeight, contentMode: .fit)
        .frame(width: 140) // You can adjust this
        .padding()
    }
}
