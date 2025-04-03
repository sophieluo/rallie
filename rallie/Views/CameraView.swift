import SwiftUI

struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CameraPreviewControllerWrapper(controller: cameraController)
                .ignoresSafeArea()

            CourtOverlayView(courtLines: cameraController.projectedCourtLines)

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

                // ✅ Centered red box
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red, lineWidth: 4)
                    .frame(width: 500, height: 20)
                    .padding(.bottom, 0)

                Text("Align the near service line with the red box")
                    .foregroundColor(.white)
                    .font(.title3)
                    .padding(.top, 12)

                Spacer()

                Button(action: {
                    print("Start tapped")
                }) {
                    Text("Start")
                        .font(.title2)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Spacer().frame(height: 30)
            }
        }
    }
}
