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

    // MARK: - Homography Output
    @Published var projectedCourtLines: [LineSegment] = []
    
    @Published var lastProjectedTap: CGPoint? = nil
    //private var homographyMatrix: [NSNumber]? = nil  // Store computed matrix for reuse
    @Published var homographyMatrix: [NSNumber]? = nil
    
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

        // Start camera session
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }

        // Compute court projection once
        computeCourtHomography()
    }

    func stopSession() {
        session.stopRunning()
        DispatchQueue.main.async {
            self.previewLayer?.removeFromSuperlayer()
            self.previewLayer = nil
            self.output = nil
        }
    }

    func computeCourtHomography() {
        let courtPoints = CourtLayout.referenceCourtPoints
        let imagePoints = CourtLayout.referenceImagePoints

        // Compute and store raw matrix
        guard let matrix = HomographyHelper.computeHomographyMatrix(from: imagePoints, to: courtPoints) else {
            print("❌ Homography matrix computation failed.")
            return
        }
        self.homographyMatrix = matrix

        // Define reference court lines in court space
        let courtLines: [LineSegment] = [
            LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 8.23, y: 0)),       // near service line
            LineSegment(start: CGPoint(x: 0, y: 5.49), end: CGPoint(x: 8.23, y: 5.49)), // baseline
            LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 5.49)),       // left sideline
            LineSegment(start: CGPoint(x: 8.23, y: 0), end: CGPoint(x: 8.23, y: 5.49)), // right sideline
            LineSegment(start: CGPoint(x: 4.115, y: 0), end: CGPoint(x: 4.115, y: 5.49))// center service line
        ]

        // Project lines using the computed matrix
        let transformedLines: [LineSegment] = courtLines.compactMap { line in
            guard let p1 = HomographyHelper.project(point: line.start, using: matrix),
                  let p2 = HomographyHelper.project(point: line.end, using: matrix) else {
                return nil
            }
            return LineSegment(start: p1, end: p2)
        }

        // Update UI on main thread
        DispatchQueue.main.async {
            self.projectedCourtLines = transformedLines
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

    func handleUserTap(_ location: CGPoint) {
        guard let matrix = homographyMatrix else {
            print("❌ Cannot project tap — matrix not ready")
            return
        }

        if let projected = HomographyHelper.project(point: location, using: matrix) {
            DispatchQueue.main.async {
                self.lastProjectedTap = projected
            }
        }
    }


}

