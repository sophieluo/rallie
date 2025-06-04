import SwiftUI
import UIKit

struct CannyEdgeDetectionView: View {
    @ObservedObject var cameraController: CameraController
    @State private var lowerThreshold: Double = 50
    @State private var upperThreshold: Double = 150
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showControls = true
    @State private var detectedCorners: [CGPoint] = []
    @State private var hasDetectedCorners = false
    
    var body: some View {
        ZStack {
            // Display the processed image if available
            if let image = processedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            
            // Display detected corners
            ForEach(0..<detectedCorners.count, id: \.self) { index in
                Circle()
                    .fill(cornerColor(for: index))
                    .frame(width: 30, height: 30)
                    .opacity(0.7)
                    .position(detectedCorners[index])
            }
            
            VStack {
                // Header with brand name
                HStack {
                    Text("canny")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                    
                    Spacer()
                    
                    // Toggle controls visibility
                    Button(action: {
                        withAnimation {
                            showControls.toggle()
                        }
                    }) {
                        Image(systemName: showControls ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Controls
                if showControls {
                    VStack(spacing: 20) {
                        // Lower threshold slider
                        VStack(alignment: .leading) {
                            Text("Lower Threshold: \(Int(lowerThreshold))")
                                .foregroundColor(.white)
                            
                            Slider(value: $lowerThreshold, in: 0...255, step: 1)
                                .accentColor(.blue)
                                .onChange(of: lowerThreshold) { _ in
                                    processImage()
                                }
                        }
                        
                        // Upper threshold slider
                        VStack(alignment: .leading) {
                            Text("Upper Threshold: \(Int(upperThreshold))")
                                .foregroundColor(.white)
                            
                            Slider(value: $upperThreshold, in: 0...255, step: 1)
                                .accentColor(.blue)
                                .onChange(of: upperThreshold) { _ in
                                    processImage()
                                }
                        }
                        
                        // Process button
                        Button(action: {
                            processImage()
                        }) {
                            Text(isProcessing ? "Processing..." : "Detect Court Corners")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isProcessing)
                        
                        // Use detected corners button
                        if hasDetectedCorners {
                            Button(action: {
                                useDetectedCorners()
                            }) {
                                Text("Use These Corners")
                                    .font(.headline)
                                    .padding()
                                    .background(Color.green.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        
                        // Return to manual calibration
                        Button(action: {
                            cameraController.cannyModeActive = false
                        }) {
                            Text("Switch to Manual Calibration")
                                .font(.headline)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding()
                    .transition(.move(edge: .bottom))
                }
            }
            
            // Loading indicator
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                    .background(Color.black.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .cornerRadius(15)
            }
        }
        .onAppear {
            // Capture initial frame when view appears
            captureAndProcessFrame()
        }
    }
    
    private func cornerColor(for index: Int) -> Color {
        let colors: [Color] = [.red, .green, .blue, .yellow]
        return colors[index % colors.count]
    }
    
    private func captureAndProcessFrame() {
        guard let currentFrame = cameraController.getCurrentFrame() else {
            print("❌ No frame available to process")
            return
        }
        
        processImageWithCanny(currentFrame)
    }
    
    private func processImage() {
        guard let currentFrame = cameraController.getCurrentFrame() else {
            print("❌ No frame available to process")
            return
        }
        
        processImageWithCanny(currentFrame)
        detectCourtCorners(currentFrame)
    }
    
    private func processImageWithCanny(_ image: UIImage) {
        isProcessing = true
        
        // Process in background to avoid UI freezing
        DispatchQueue.global(qos: .userInitiated).async {
            let processedImage = OpenCVWrapper.cannyEdgeDetection(
                with: image,
                lowerThreshold: self.lowerThreshold,
                upperThreshold: self.upperThreshold
            )
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.processedImage = processedImage
                self.isProcessing = false
            }
        }
    }
    
    private func detectCourtCorners(_ image: UIImage) {
        isProcessing = true
        
        // Process in background to avoid UI freezing
        DispatchQueue.global(qos: .userInitiated).async {
            if let corners = OpenCVWrapper.detectCourtCorners(
                inImage: image,
                lowerThreshold: self.lowerThreshold,
                upperThreshold: self.upperThreshold
            ) as? [NSValue] {
                
                // Convert NSValue array to CGPoint array
                let cgPointCorners = corners.map { $0.cgPointValue }
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.detectedCorners = cgPointCorners
                    self.hasDetectedCorners = cgPointCorners.count == 4
                    self.isProcessing = false
                    
                    if self.hasDetectedCorners {
                        print("✅ Successfully detected 4 court corners")
                    } else {
                        print("⚠️ Could not detect exactly 4 court corners")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    print("❌ Failed to detect court corners")
                }
            }
        }
    }
    
    private func useDetectedCorners() {
        guard detectedCorners.count == 4 else { return }
        
        // Update the camera controller's calibration points with detected corners
        cameraController.calibrationPoints = detectedCorners
        
        // Compute homography using the detected corners
        cameraController.computeHomographyFromCalibrationPoints()
        
        // Exit calibration mode
        cameraController.isCalibrationMode = false
        cameraController.cannyModeActive = false
        
        print("✅ Applied detected corners to calibration")
    }
}

// Extension to CameraController to add Canny mode support
extension CameraController {
    @Published var cannyModeActive: Bool = false
    
    func getCurrentFrame() -> UIImage? {
        guard let pixelBuffer = self.currentPixelBuffer else {
            return nil
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
