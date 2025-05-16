//
//  CalibrationPointsView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 5/10/25.
//

import SwiftUI

struct CalibrationPointsView: View {
    @ObservedObject var cameraController: CameraController
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw lines connecting the calibration points to form a court outline
                Path { path in
                    if cameraController.calibrationPoints.count >= 4 {
                        let points = cameraController.calibrationPoints
                        
                        // Main court outline
                        path.move(to: points[0])
                        path.addLine(to: points[1])
                        path.addLine(to: points[2])
                        path.addLine(to: points[3])
                        path.closeSubpath()
                        
                        // If we have service line points, draw them too
                        if points.count >= 7 {
                            // Service line
                            path.move(to: points[4])
                            path.addLine(to: points[5])
                            
                            // Center service line
                            path.move(to: points[6])
                            path.addLine(to: CGPoint(x: points[6].x, y: points[0].y))
                        }
                    }
                }
                .stroke(Color.red.opacity(0.8), lineWidth: 2)
                
                // Draw draggable points
                ForEach(0..<min(4, cameraController.calibrationPoints.count), id: \.self) { i in
                    DraggablePoint(
                        position: Binding(
                            get: { cameraController.calibrationPoints[i] },
                            set: { cameraController.calibrationPoints[i] = $0 }
                        ),
                        color: pointColor(for: i)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func pointColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .green, .yellow, .purple]
        return colors[index % colors.count]
    }
}

struct DraggablePoint: View {
    @Binding var position: CGPoint
    var color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 30, height: 30)
            .opacity(0.7)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        position = value.location
                    }
            )
    }
}