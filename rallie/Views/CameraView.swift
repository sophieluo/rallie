import SwiftUI
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss

    //share csv
    @State private var showShareSheet = false
    @State private var csvURL: URL? = nil

    //broadcast player position
    @StateObject var bluetoothManager = BluetoothManager()
    @StateObject var logicManager: LogicManager

    init(cameraController: CameraController) {
        _cameraController = ObservedObject(wrappedValue: cameraController)
        let bluetooth = BluetoothManager()
        _bluetoothManager = StateObject(wrappedValue: bluetooth)
        _logicManager = StateObject(wrappedValue: LogicManager(
            playerPositionPublisher: cameraController.$projectedPlayerPosition,
            bluetoothManager: bluetooth
        ))
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let _ = print("📏 Geometry size: \(geometry.size)")

                CameraPreviewControllerWrapper(controller: cameraController)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                if cameraController.isTappingEnabled {
                                    cameraController.handleUserTap(location)
                                }
                            }
                    )
            }
            .ignoresSafeArea()

            // Alignment overlay
            OverlayShapeView(isActivated: cameraController.isTappingEnabled)

            // Mini court in top-right
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
                .padding(.top, 60)  // Add padding to move it higher
                
                Text("Align the court to fit the red outline")
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
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

                // Only show alignment button if not yet aligned
                if !cameraController.isTappingEnabled {
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
                    .padding(.bottom, 10)
                }

                // Export CSV button in bottom right
                HStack {
                    Spacer()
                    Button("Export CSV") {
                        if let fileURL = getCSVURL() {
                            self.csvURL = fileURL
                            self.showShareSheet = true
                        }
                    }
                    .foregroundColor(.white)
                    .underline()
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
                .sheet(isPresented: $showShareSheet) {
                    if let file = csvURL {
                        ShareSheet(activityItems: [file])
                    }
                }
            }
        }
        .onAppear {
            print("👀 CameraView appeared")

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let screenSize = window.bounds.size
                print("📲 Starting camera session with screen size: \(screenSize)")
                
                cameraController.startSession(in: window, screenSize: screenSize)
            }
        }
        .onDisappear {
            print("👋 CameraView disappeared")
            cameraController.stopSession()
        }
    }

    func getCSVURL() -> URL? {
        let fileName = "player_positions.csv"
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(fileName)
            return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
        }
        return nil
    }
}

// MARK: - ShareSheet Helper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

