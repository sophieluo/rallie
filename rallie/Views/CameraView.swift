import SwiftUI
import UniformTypeIdentifiers

@available(iOS 16.0, *)
struct CameraView: View {
    @ObservedObject var cameraController: CameraController
    @Environment(\.dismiss) private var dismiss

    //share csv
    @State private var showShareSheet = false
    @State private var csvURL: URL? = nil
    @State private var showExportAlert = false

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
            OverlayShapeView(
                isActivated: cameraController.isTappingEnabled,
                playerDetector: cameraController.playerDetector
            )

            VStack {
                // Instruction text moved to top
                Text("Align the court to fit the red outline")
                    .foregroundColor(.white)
                    .padding(.top, 40)  // Increased top padding
                
                // Mini court in top-right with Export CSV
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 10) {  // Added spacing
                        MiniCourtView(
                            tappedPoint: cameraController.lastProjectedTap,
                            playerPosition: cameraController.projectedPlayerPosition
                        )
                        .frame(width: 140, height: 100)
                        
                        // Export CSV button moved up
                        Button {
                            if let fileURL = getCSVURL() {
                                self.csvURL = fileURL
                                self.showShareSheet = true
                                print("📁 CSV file location: \(fileURL.path)")
                            } else {
                                print("❌ No CSV file found")
                            }
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export CSV")
                            }
                            .foregroundColor(.white)
                            .underline()
                        }
                        .alert("CSV Export", isPresented: $showExportAlert) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            if let url = csvURL {
                                Text("File saved at:\n\(url.path)\n\nUse the share sheet to save to Files app or share via AirDrop.")
                            } else {
                                Text("No data recorded yet.")
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }

                Spacer()

                // Buttons at bottom
                VStack {
                    // Close button
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

                    // Alignment button moved up
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
                        .padding(.bottom, 50)  // Increased bottom padding
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let file = csvURL {
                ShareSheet(activityItems: [file])
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

    private func checkCSVContents() -> Bool {
        guard let fileURL = getCSVURL(),
              let contents = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return false
        }
        return !contents.isEmpty
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

