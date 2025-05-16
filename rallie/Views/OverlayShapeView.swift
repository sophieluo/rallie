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
    @ObservedObject var cameraController: CameraController
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Path { path in
                    // Draw court lines using the projected lines from homography
                    for line in cameraController.projectedCourtLines {
                        path.move(to: line.start)
                        path.addLine(to: line.end)
                    }
                }
                .stroke(Color.red.opacity(isActivated ? 1.0 : 0.3), lineWidth: 2)
            }
        }
        .ignoresSafeArea()
    }
}
