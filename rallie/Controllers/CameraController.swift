//
//  CameraController.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import Foundation
import AVFoundation
import UIKit

class CameraController: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

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

        session.startRunning()
    }

    func stopSession() {
        session.stopRunning()
    }
}
