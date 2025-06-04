// MARK: - CameraController.swift

import Foundation
import AVFoundation
import UIKit
import Vision
import Combine

class CameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var output: AVCaptureVideoDataOutput?
    private var lastLogTime: Date? = nil

    // MARK: - Vision
    var playerDetector = PlayerDetector()

    // MARK: - Outputs
    @Published var projectedCourtLines: [LineSegment] = []
    @Published var lastProjectedTap: CGPoint? = nil
    @Published var homographyMatrix: [NSNumber]? = nil
    @Published var projectedPlayerPosition: CGPoint? = nil
    @Published var isTappingEnabled = false
    
    // Store the current pixel buffer for image processing
    var currentPixelBuffer: CVPixelBuffer?

    // MARK: - Calibration Points
    @Published var calibrationPoints: [CGPoint] = []
    @Published var isCalibrationMode = true

    // MARK: - Setup
    func startSession(in view: UIView, screenSize: CGSize) {
        print("🎥 Starting camera session setup")
        
        // Check if session is already running
        guard !session.isRunning else {
            print("⚠️ Session already running")
            return
        }

        session.sessionPreset = .high
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                print("❌ Cannot add camera input")
                return
            }
            session.addInput(input)
            print("✅ Camera input added successfully")
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
            guard session.canAddOutput(output) else {
                print("❌ Cannot add video output")
                return
            }
            session.addOutput(output)
            self.output = output
            print("✅ Video output added successfully")

            previewLayer?.removeFromSuperlayer()
            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            preview.connection?.videoOrientation = .landscapeRight
            view.layer.insertSublayer(preview, at: 0)
            self.previewLayer = preview
            print("✅ Preview layer configured")

            session.beginConfiguration()
            if let connection = output.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .landscapeRight
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = false
                }
            }
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                print("🎬 Starting capture session")
                self?.session.startRunning()
                print("✅ Capture session started")
            }

            // Initialize calibration points instead of computing homography directly
            initializeCalibrationPoints(for: screenSize)
            
        } catch {
            print("❌ Camera setup error: \(error.localizedDescription)")
        }
    }

    func stopSession() {
        print("🛑 Stopping camera session")
        session.stopRunning()
        DispatchQueue.main.async { [weak self] in
            self?.previewLayer?.removeFromSuperlayer()
            self?.previewLayer = nil
            self?.output = nil
        }
        print("✅ Camera session stopped")
    }

    // MARK: - Calibration Points
    func initializeCalibrationPoints(for screenSize: CGSize) {
        // Initialize with default points based on screen size
        let topY = screenSize.height * 0.45  
        let bottomY = screenSize.height * 0.88
        let topInset = screenSize.width * 0.35  
        let bottomInset = screenSize.width * 0.05
        
        calibrationPoints = [
            CGPoint(x: bottomInset, y: bottomY),         // bottom left
            CGPoint(x: screenSize.width - bottomInset, y: bottomY), // bottom right
            CGPoint(x: screenSize.width - topInset, y: topY),  // top right
            CGPoint(x: topInset, y: topY),               // top left
        ]
        
        // Calculate service line points
        let serviceLineY = topY + (bottomY - topY) * 0.35
        let leftX1 = bottomInset
        let leftX2 = topInset
        let leftY1 = bottomY
        let leftY2 = topY
        
        let rightX1 = screenSize.width - bottomInset
        let rightX2 = screenSize.width - topInset
        let rightY1 = bottomY
        let rightY2 = topY
        
        let leftServiceX = leftX1 + (leftX2 - leftX1) * ((serviceLineY - leftY1) / (leftY2 - leftY1))
        let rightServiceX = rightX1 + (rightX2 - rightX1) * ((serviceLineY - rightY1) / (rightY2 - rightY1))
        let centerX = (leftServiceX + rightServiceX) / 2
        
        // Add service line points
        calibrationPoints.append(CGPoint(x: leftServiceX, y: serviceLineY))    // left service
        calibrationPoints.append(CGPoint(x: rightServiceX, y: serviceLineY))   // right service
        calibrationPoints.append(CGPoint(x: centerX, y: serviceLineY))         // center service
        calibrationPoints.append(CGPoint(x: centerX, y: serviceLineY))         // center service (duplicate)
    }

    func computeHomographyFromCalibrationPoints() {
        guard calibrationPoints.count >= 4 else {
            print("❌ Not enough calibration points")
            return
        }
        
        let courtPoints = CourtLayout.referenceCourtPoints
        
        guard let matrix = HomographyHelper.computeHomographyMatrix(from: calibrationPoints, to: courtPoints) else {
            print("❌ Homography matrix computation failed.")
            return
        }
        self.homographyMatrix = matrix
        
        // Update court lines using the new homography
        let courtLines: [LineSegment] = [
            // Baseline (y = 0)
            LineSegment(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 8.23, y: 0)),
            // Right sideline
            LineSegment(start: CGPoint(x: 8.23, y: 0), end: CGPoint(x: 8.23, y: 11.885)),
            // Net line (y = 11.885)
            LineSegment(start: CGPoint(x: 8.23, y: 11.885), end: CGPoint(x: 0, y: 11.885)),
            // Left sideline
            LineSegment(start: CGPoint(x: 0, y: 11.885), end: CGPoint(x: 0, y: 0)),
        ]
        
        let transformedLines = courtLines.compactMap { line -> LineSegment? in
            guard let p1 = HomographyHelper.project(point: line.start, using: matrix, trapezoidCorners: Array(calibrationPoints.prefix(4))),
                  let p2 = HomographyHelper.project(point: line.end, using: matrix, trapezoidCorners: Array(calibrationPoints.prefix(4))) else {
                return nil
            }
            return LineSegment(start: p1, end: p2)
        }
        
        DispatchQueue.main.async {
            self.projectedCourtLines = transformedLines
        }
    }

    // MARK: - Homography
    func computeCourtHomography(for screenSize: CGSize) {
        // Removed the original implementation
    }

    // MARK: - Frame Processing
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get pixel buffer")
            return
        }
        
        // Store the current pixel buffer for Canny edge detection
        self.currentPixelBuffer = pixelBuffer
        
        if !session.isRunning {
            print("⚠️ Session not running during frame processing")
            return
        }
        
        playerDetector.processPixelBuffer(pixelBuffer)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let matrix = self.homographyMatrix else {
                print("❌ Missing homography matrix")
                return
            }
            
            let trapezoidCorners = self.calibrationPoints.prefix(4)
            
            guard let footPos = self.playerDetector.footPositionInImage else {
                // Only print every few seconds to avoid log spam
                if let last = self.lastLogTime, Date().timeIntervalSince(last) > 2.0 {
                    print("ℹ️ No foot position detected")
                    self.lastLogTime = Date()
                }
                return
            }
            
            if let projected = HomographyHelper.project(point: footPos, using: matrix, trapezoidCorners: Array(trapezoidCorners)) {
                self.projectedPlayerPosition = projected
                self.logPlayerPositionCSV(projected)
                print("👟 Projected feet: \(projected)")
                self.updatePlayerPosition(projected)
            }
        }
    }

    // MARK: - Tap Handling
    func handleUserTap(_ location: CGPoint) {
        guard let matrix = homographyMatrix else {
            print("❌ Missing homography matrix")
            return
        }
        
        let trapezoidCorners = calibrationPoints.prefix(4)
        
        guard let projected = HomographyHelper.project(point: location, using: matrix, trapezoidCorners: Array(trapezoidCorners)) else {
            print("❌ Tap projection failed")
            return
        }

        if (0...8.23).contains(projected.x) && (0...11.885).contains(projected.y) {
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
    
    private func logPlayerPositionCSV(_ point: CGPoint) {
        let now = Date()

        // Only log if at least 1 second has passed
        if let last = lastLogTime, now.timeIntervalSince(last) < 1.0 {
            return
        }

        lastLogTime = now

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = dateFormatter.string(from: now)

        let row = "\(timestamp),\(point.x),\(point.y)\n"
        let fileName = "player_positions.csv"

        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Failed to get document directory")
            return
        }

        let fileURL = dir.appendingPathComponent(fileName)
        print("📝 CSV Path: \(fileURL.path)")

        do {
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                // Create new file with header
                let header = "timestamp,x,y\n"
                try (header + row).write(to: fileURL, atomically: true, encoding: .utf8)
                print("✅ Created new CSV file with header")
            } else {
                // Append to existing file
                let handle = try FileHandle(forWritingTo: fileURL)
                defer { handle.closeFile() } // Ensures file is closed even if an error occurs
                
                handle.seekToEndOfFile()
                if let data = row.data(using: .utf8) {
                    handle.write(data)
                    print("✅ Appended position: \(point.x), \(point.y)")
                }
            }
        } catch {
            print("❌ CSV write error: \(error.localizedDescription)")
        }
    }

    // Add this helper method to get the CSV file URL
    func getCSVFileURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("player_positions.csv")
    }

    let playerPositionPublisher = PassthroughSubject<CGPoint, Never>()

    private func updatePlayerPosition(_ point: CGPoint) {
        DispatchQueue.main.async {
            self.projectedPlayerPosition = point
            self.playerPositionPublisher.send(point) // ✅ broadcast position
        }
    }
}
