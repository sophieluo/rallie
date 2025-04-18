//
//  OverlayShapeView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/12/25.
//

import SwiftUI

struct OverlayShapeView: View {
    var isActivated: Bool
    @ObservedObject var playerDetector: PlayerDetector
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                let points = CourtLayout.referenceImagePoints(for: geometry.size)
                
                Path { path in
                    // Main court outline
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.addLine(to: points[2])
                    path.addLine(to: points[3])
                    path.closeSubpath()
                    
                    // Service line
                    path.move(to: points[4])
                    path.addLine(to: points[5])
                    
                    // Center service line (from net to service line)
                    let centerX = (points[2].x + points[3].x) / 2  // Center X at net
                    path.move(to: CGPoint(x: centerX, y: points[2].y))  // Start at net
                    path.addLine(to: points[6])  // End at service line
                }
                .stroke(Color.red.opacity(isActivated ? 1.0 : 0.3), lineWidth: 2)
                
                // Optional: Draw points for debugging
                if isActivated {
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                            .position(points[i])
                    }
                }
                
                // Add bounding box if available
                if let box = playerDetector.boundingBox {
                    // Account for landscape orientation
                    let rect = CGRect(
                        x: box.origin.y * geometry.size.width,  // Swap x/y for landscape
                        y: box.origin.x * geometry.size.height,
                        width: box.height * geometry.size.width, // Swap width/height too
                        height: box.width * geometry.size.height
                    )
                    
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .ignoresSafeArea()
    }
}
