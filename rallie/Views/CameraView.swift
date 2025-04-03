import SwiftUI

struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss   // ✅ dismiss environment

    var body: some View {
        ZStack {
            CameraPreviewControllerWrapper(controller: cameraController)
                .ignoresSafeArea()

            CourtOverlayView(courtLines: cameraController.projectedCourtLines)

            VStack {
                HStack {
                    Button(action: {
                        cameraController.stopSession()   // ✅ stop camera
                        dismiss()                        // ✅ dismiss view
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red, lineWidth: 2)
                    .frame(width: 160, height: 10)
                    .padding(.bottom, 120)

                Text("Align the near service line with the red box")
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                Button(action: {
                    print("Start tapped")
                }) {
                    Text("Start")
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

