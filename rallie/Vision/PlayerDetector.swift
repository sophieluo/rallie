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
                print("👤 No person detected")
                return
            }
            
            // For back-facing detection, focus on these more reliable points
            let confidenceThreshold: CGFloat = 0.5
            
            if let recognizedPoints = try? observation.recognizedPoints(.all) {
                // First check if we have at least one foot with good confidence
                let rightFoot = CGFloat(recognizedPoints[.rightAnkle]?.confidence ?? 0)
                let leftFoot = CGFloat(recognizedPoints[.leftAnkle]?.confidence ?? 0)
                
                // Use the most confident foot for position
                if rightFoot > confidenceThreshold || leftFoot > confidenceThreshold {
                    let bestFoot = rightFoot > leftFoot ? recognizedPoints[.rightAnkle] : 
                                                         recognizedPoints[.leftAnkle]
                    if let footPoint = bestFoot {
                        // Change coordinate handling to match tap coordinates
                        // Instead of flipping Y, we'll swap X and Y for landscape orientation
                        let anklePosition = CGPoint(x: 1 - footPoint.location.y,  // Swap and invert Y to X
                                                  y: footPoint.location.x)        // Use X as Y
                        
                        print("👣 Best foot position - raw: \(footPoint.location), transformed: \(anklePosition), confidence: \(footPoint.confidence)")
                        
                        DispatchQueue.main.async {
                            self.footPositionInImage = anklePosition
                        }
                    }
                } else {
                    print("🦶 No feet detected with sufficient confidence")
                    DispatchQueue.main.async {
                        self.footPositionInImage = nil
                    }
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
