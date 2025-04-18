//
//  PlayerDetector.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import Vision
import UIKit

class PlayerDetector: ObservableObject {
    @Published var footPositionInImage: CGPoint? = nil
    @Published var boundingBox: CGRect? = nil
    
    private let sequenceHandler = VNSequenceRequestHandler()
    private lazy var request: VNDetectHumanBodyPoseRequest = {
        let request = VNDetectHumanBodyPoseRequest { [weak self] (request: VNRequest, error: Error?) in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                DispatchQueue.main.async {
                    self?.footPositionInImage = nil
                    self?.boundingBox = nil
                }
                return
            }
            
            // Calculate bounding box from all detected points
            var minX: CGFloat = 1.0
            var minY: CGFloat = 1.0
            var maxX: CGFloat = 0.0
            var maxY: CGFloat = 0.0
            
            // Check all recognized points to find bounds
            if let recognizedPoints = try? observation.recognizedPoints(.all) {
                for (_, point) in recognizedPoints {  // Use tuple pattern to iterate dictionary
                    guard point.confidence > 0.3 else { continue }
                    let location = point.location  // Remove .value since point is already a VNRecognizedPoint
                    minX = min(minX, location.x)
                    minY = min(minY, location.y)
                    maxX = max(maxX, location.x)
                    maxY = max(maxY, location.y)
                }
                
                // Print raw bounding box values before transformation
                print("🔍 Raw bounding box - minX: \(minX), minY: \(minY), maxX: \(maxX), maxY: \(maxY)")
            }
            
            // Only update if we found valid points
            if minX < maxX && minY < maxY {
                let box = CGRect(x: minX,
                               y: 1 - maxY,  // Flip Y coordinate
                               width: maxX - minX,
                               height: maxY - minY)
                
                print("📦 Transformed box - origin: \(box.origin), size: \(box.size)")
                
                DispatchQueue.main.async {
                    self.boundingBox = box
                }
            }
            
            // Get ankle points (more reliable than full body box)
            if let rightAnkle = try? observation.recognizedPoint(.rightAnkle),
               rightAnkle.confidence > 0.3 {
                
                // Vision coordinates are in normalized space (0,0 to 1,1)
                let anklePosition = CGPoint(x: rightAnkle.location.x,
                                         y: 1 - rightAnkle.location.y)  // Flip Y coordinate
                
                DispatchQueue.main.async {
                    print("👣 Detected foot position: \(anklePosition)")
                    self.footPositionInImage = anklePosition
                }
            } else {
                DispatchQueue.main.async {
                    self.footPositionInImage = nil
                }
            }
        }
        return request
    }()
    
    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([request])
        } catch {
            print("❌ Vision error: \(error)")
        }
    }
}
