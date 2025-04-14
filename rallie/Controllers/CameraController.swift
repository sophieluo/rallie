// MARK: - CameraController.swift

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

    // MARK: - Outputs
    @Published var projectedCourtLines: [LineSegment] = []
    @Published var lastProjectedTap: CGPoint? = nil
    @Published var homographyMatrix: [NSNumber]? = nil
    @Published var projectedPlayerPosition: CGPoint? = nil
    @Published var isTappingEnabled = false

    // MARK: - Setup
    func startSession(in view: UIView, screenSize: CGSize) {
        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Camera input setup failed")
            return
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        guard session.canAddOutput(output) else {
            print("❌ Failed to add video output")
            return
        }
        session.addOutput(output)
        self.output = output

        previewLayer?.removeFromSuperlayer()
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        preview.connection?.videoOrientation = .landscapeRight
        view.layer.insertSublayer(preview, at: 0)
        self.previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }

        computeCourtHomography(for: screenSize)
    }

    func stopSession() {
        session.stopRunning()
        DispatchQueue.main.async {
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = nil
            self.output = nil
        }
    }

    // MARK: - Homography
    func computeCourtHomography(for screenSize: CGSize) {
        let imagePoints = CourtLayout.referenceImagePoints(for: screenSize)
        let courtPoints = CourtLayout.referenceCourtPoints

        guard let matrix = HomographyHelper.computeHomographyMatrix(from: imagePoints, to: courtPoints) else {
            print("❌ Homography matrix computation failed.")
            return
        }
        self.homographyMatrix = matrix

        let courtLines: [LineSegment] = [
            LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 8.23, y: 0)),
            LineSegment(start: CGPoint(x: 0, y: 5.49), end: CGPoint(x: 8.23, y: 5.49)),
            LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 5.49)),
            LineSegment(start: CGPoint(x: 8.23, y: 0), end: CGPoint(x: 8.23, y: 5.49)),
            LineSegment(start: CGPoint(x: 4.115, y: 0), end: CGPoint(x: 4.115, y: 5.49))
        ]

        let transformedLines = courtLines.compactMap { line -> LineSegment? in
            guard let p1 = HomographyHelper.project(point: line.start, using: matrix),
                  let p2 = HomographyHelper.project(point: line.end, using: matrix) else {
                return nil
            }
            return LineSegment(start: p1, end: p2)
        }

        DispatchQueue.main.async {
            self.projectedCourtLines = transformedLines
        }
    }

    // MARK: - Frame Processing
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        playerDetector.processPixelBuffer(pixelBuffer)

        DispatchQueue.main.async {
            guard let matrix = self.homographyMatrix,
                  let footPos = self.playerDetector.footPositionInImage else { return }

            let screenSize = UIScreen.main.bounds.size
            let footPixel = CGPoint(x: footPos.x * screenSize.width,
                                    y: footPos.y * screenSize.height)

            if let projected = HomographyHelper.project(point: footPixel, using: matrix) {
                self.projectedPlayerPosition = projected
                print("👟 Projected feet: \(projected)")
            }
        }
    }

    // MARK: - Tap Handling
    func handleUserTap(_ location: CGPoint) {
        guard let matrix = homographyMatrix,
              var projected = HomographyHelper.project(point: location, using: matrix) else {
            print("❌ Tap projection failed")
            return
        }

        projected.y = 5.49 - projected.y

        if (0...8.23).contains(projected.x) && (0...5.49).contains(projected.y) {
            DispatchQueue.main.async {
                self.lastProjectedTap = projected
                print("✅ Tap accepted: \(projected)")
            }
        } else {
            print("⚠️ Tap outside bounds: \(projected)")
        }
    }

    func updatePreviewFrame(to bounds: CGRect) {
        DispatchQueue.main.async {
            self.previewLayer?.frame = bounds
        }
    }
}


