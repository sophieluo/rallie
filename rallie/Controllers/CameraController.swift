//
//  CameraController.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import Foundation
import AVFoundation
import UIKit
import Vision

class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Vision
    var playerDetector = PlayerDetector()

    // MARK: - Homography
    var homographyPoints: [CGPoint]? = nil  // Optional output after compute

    /// Hardcoded image-space points for initial court alignment (in pixels)
    var imagePoints: [CGPoint] {
        return [
            CGPoint(x: 120, y: 450), // near left service line
            CGPoint(x: 260, y: 450), // near right service line
            CGPoint(x: 120, y: 150), // far left baseline
            CGPoint(x: 260, y: 150)  // far right baseline
        ]
    }

    // MARK: - Session Setup
    func startSession(in view: UIView) {
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ Failed to set up camera input")
            return
        }

        session.addInput(input)

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        self.previewLayer = preview

        // Add live video output for Vision
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        session.addOutput(output)

        session.startRunning()

        // 👇 Compute homography on start
        computeCourtHomography()
    }

    func stopSession() {
        session.stopRunning()
    }

    // MARK: - Compute Homography
    func computeCourtHomography() {
        let courtReferencePoints = CourtLayout.referencePoints

        let result = HomographyHelper.computeHomography(from: imagePoints, to: courtReferencePoints)
        self.homographyPoints = result

        if let matrix = result {
            print("✅ Homography computed: \(matrix)")
        } else {
            print("❌ Failed to compute homography")
        }
    }

    // MARK: - AVCapture Delegate (frame-by-frame)
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Run Vision player detection
        playerDetector.processPixelBuffer(pixelBuffer)

        // Later: Use `homographyPoints` to transform player position
    }
}

