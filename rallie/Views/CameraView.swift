//
//  CameraView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var controller = CameraController()

    var body: some View {
        ZStack {
            CameraPreviewView(controller: controller)
                .ignoresSafeArea()

            GeometryReader { geo in
                // ROTATED UI OVER PORTRAIT CAMERA
                ZStack {
                    // Pink rectangle + prompt
                    VStack(spacing: 20) {
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.pink, lineWidth: 6)
                            .frame(width: geo.size.height * 0.6, height: 16) // wide box
                        Text("Align the near service line to be\ninside the pink rectangle for best results")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .rotationEffect(.degrees(90))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 + 60)

                    // Close button (top-left in landscape)
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    }
                    .rotationEffect(.degrees(90))
                    .position(x: 40, y: 60)

                    // START button (bottom-right in landscape)
                    Button(action: {
                        // handle start recording
                    }) {
                        Text("START")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 80, height: 80)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .rotationEffect(.degrees(90))
                    .position(x: geo.size.width - 60, y: geo.size.height - 80)
                }
            }
        }
    }
}

