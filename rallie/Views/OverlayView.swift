//
//  OverlayView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import SwiftUI

struct OverlayView: View {
    @ObservedObject var detector: PlayerDetector
    var body: some View {
        GeometryReader { geo in
            let rect = detector.boundingBox
            let frame = CGRect(
                x: rect.minX * geo.size.width,
                y: (1 - rect.maxY) * geo.size.height,
                width: rect.width * geo.size.width,
                height: rect.height * geo.size.height
            )

            Rectangle()
                .stroke(Color.green, lineWidth: 3)
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .animation(.easeInOut(duration: 0.1), value: detector.boundingBox)
        }
    }
}
