import SwiftUI

struct MiniCourtView: View {
    let tappedPoint: CGPoint?           // 🟢 From user tap
    let playerPosition: CGPoint?        // 🎾 From Vision

    let courtWidth: CGFloat = 8.23
    let courtHeight: CGFloat = 5.49

    var body: some View {
        GeometryReader { geo in
            let scaleX = geo.size.width / courtWidth
            let scaleY = geo.size.height / courtHeight

            ZStack {
                // 🏟 Court lines
                Path { path in
                    // Outer rectangle
                    path.addRect(CGRect(x: 0, y: 0,
                                        width: courtWidth * scaleX,
                                        height: courtHeight * scaleY))

                    // Center service line
                    let centerX = (courtWidth / 2) * scaleX
                    path.move(to: CGPoint(x: centerX, y: 0))
                    path.addLine(to: CGPoint(x: centerX, y: courtHeight * scaleY))
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 1)

                // 🟢 Tapped dot
                if let pt = tappedPoint {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(x: pt.x * scaleX, y: pt.y * scaleY)
                }

                // 🎾 Player position dot
                if let player = playerPosition {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 10)
                        .position(x: player.x * scaleX, y: player.y * scaleY)
                }
            }
        }
        .aspectRatio(courtWidth / courtHeight, contentMode: .fit)
        .frame(width: 140)
        .padding(.top, 10)
        .padding(.trailing, 10)
    }
}

