import SwiftUI

struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Camera feed + tap gesture
            CameraPreviewControllerWrapper(controller: cameraController)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            if cameraController.isTappingEnabled {
                                cameraController.handleUserTap(value.location)
                            }
                        }
                )

            // Alignment overlay
            OverlayShapeView()

            // Top-right: Mini court
            VStack {
                HStack {
                    Spacer()
                    MiniCourtView(
                        tappedPoint: cameraController.lastProjectedTap,
                        playerPosition: cameraController.projectedPlayerPosition
                    )
                        .frame(width: 140, height: 100)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                Spacer()
            }

            // UI: Dismiss button + instructions + "Let's go" button
            VStack {
                HStack {
                    Button(action: {
                        cameraController.stopSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }

                Spacer()

                Text("Align the court to fit the red outline")
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                Spacer()

                Button(action: {
                    cameraController.isTappingEnabled = true
                    print("✅ Tapping is now enabled")
                }) {
                    Text("Aligned - Let's go!")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer().frame(height: 40)
            }
        }
    }
}

