//
//  OverlayShapeView.swift
//  rallie
//
//  Created by Xiexiao_Luo on 4/12/25.
//

import SwiftUI

struct OverlayShapeView: View {
    var isActivated: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let points = OverlayHelper.computeTrapezoid(in: geometry)

            Path { path in
                path.move(to: points[0])
                path.addLine(to: points[1])
                path.addLine(to: points[2])
                path.addLine(to: points[3])
                path.closeSubpath()
            }
            .stroke(Color.red.opacity(isActivated ? 1.0 : 0.3), lineWidth: 2)
        }
        .ignoresSafeArea()
    }
}
