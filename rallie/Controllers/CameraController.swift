import Foundation
import AVFoundation
import UIKit
import Vision

class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var output: AVCaptureVideoDataOutput?

    // MARK: - Vision
    var playerDetector = PlayerDetector()

    // MARK: - Homography Output
    @Published var projectedCourtLines: [LineSegment] = []

    /// Hardcoded image-space points for initial court alignment (in pixels)
    var imagePoints: [CGPoint] {
        return [
            CGPoint(x: 120, y: 450), // near left service line
            CGPoint(x: 260, y: 450), // near right service line
            CGPoint(x: 120, y: 150), // far left baseline
            CGPoint(x: 260, y: 150)  // far right baseline
        ]
    }

    func startSession(in view: UIView) {
        session.sessionPreset = .high

        // Clean old inputs/outputs if re-entering
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        // Setup input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Failed to set up camera input")
            return
        }
        session.addInput(input)

        // Setup output
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        guard session.canAddOutput(output) else {
            print("❌ Failed to add video output")
            return
        }
        session.addOutput(output)
        self.output = output

        // Remove existing preview layer if re-entering
        previewLayer?.removeFromSuperlayer()

        // Setup preview layer
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds

        if let connection = preview.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .landscapeRight
        }

        view.layer.insertSublayer(preview, at: 0)
        self.previewLayer = preview

        // Run session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }

        computeCourtHomography()
    }


    func stopSession() {
        session.stopRunning()

        // Optional: Clean preview + output if needed
        DispatchQueue.main.async {
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }

    func computeCourtHomography() {
        let courtPoints = CourtLayout.referencePoints
        let imagePoints = self.imagePoints

        // Convert to NSArray<NSValue>
        let src = imagePoints.map { NSValue(cgPoint: $0) }
        let dst = courtPoints.map { NSValue(cgPoint: $0) }

        // Compute homography matrix (as NSArray<NSValue>)
        if let rawMatrix = OpenCVWrapper.computeHomography(from: src, to: dst) {
            // Convert [NSValue<CGPoint>] to [NSNumber] by extracting .y
            let matrixValues: [NSNumber] = rawMatrix.map { NSNumber(value: Double($0.cgPointValue.y)) }

            // Define full court lines in court space (8m x 12m)
            let courtLines: [LineSegment] = [
                LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 8, y: 0)),     // near service line
                LineSegment(start: CGPoint(x: 0, y: 12), end: CGPoint(x: 8, y: 12)),   // far baseline
                LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 12)),    // left sideline
                LineSegment(start: CGPoint(x: 8, y: 0), end: CGPoint(x: 8, y: 12)),    // right sideline
                LineSegment(start: CGPoint(x: 4, y: 0), end: CGPoint(x: 4, y: 12))     // center service line
            ]

            // Project each line using homography
            let transformedLines: [LineSegment] = courtLines.compactMap { line in
                if let p1Value = OpenCVWrapper.projectPoint(line.start, usingMatrix: matrixValues),
                   let p2Value = OpenCVWrapper.projectPoint(line.end, usingMatrix: matrixValues) {
                    let p1 = p1Value.cgPointValue
                    let p2 = p2Value.cgPointValue
                    return LineSegment(start: p1, end: p2)
                }
                return nil
            }

            // Update published output on main thread
            DispatchQueue.main.async {
                self.projectedCourtLines = transformedLines
            }
        }
    }


    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        playerDetector.processPixelBuffer(pixelBuffer)
    }
    
    
    func updatePreviewFrame(to bounds: CGRect) {
        DispatchQueue.main.async {
            self.previewLayer?.frame = bounds
        }
    }

}

