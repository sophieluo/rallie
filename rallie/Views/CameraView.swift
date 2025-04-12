import SwiftUI

struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Camera + tap gesture
            CameraPreviewControllerWrapper(controller: cameraController)
                .ignoresSafeArea()
                .contentShape(Rectangle()) // needed for full-screen tap
            
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            let location = value.location
                            if cameraController.isTappingEnabled {
                                cameraController.handleUserTap(location)
                            }
                        }
                )

            // Alignment overlay
            OverlayShapeView()  // draws the trapezoid

            // Top-right corner: mini court
            VStack {
                HStack {
                    Spacer()
                    MiniCourtView(projectedPoint: cameraController.lastProjectedTap)
                        .frame(width: 140, height: 100)
                        .padding(.top, 20)
                        .padding(.trailing, 20)
                }
                Spacer()
            }

            // Buttons and label
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
                    print("Tapping is now enabled")
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

