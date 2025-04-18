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

    private var request: VNDetectHumanBodyPoseRequest!
    private var sequenceHandler = VNSequenceRequestHandler()

    init() {
        request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self,
                  let observations = request.results as? [VNHumanBodyPoseObservation],
                  let observation = observations.first else {
                DispatchQueue.main.async {
                    self?.footPositionInImage = nil
                }
                return
            }
            
            // Get ankle points (more reliable than full body box)
            guard let rightAnkle = try? observation.recognizedPoint(.rightAnkle),
                  rightAnkle.confidence > 0.3 else {
                return
            }
            
            // Vision coordinates are in normalized space (0,0 to 1,1)
            let anklePosition = CGPoint(x: rightAnkle.location.x,
                                      y: 1 - rightAnkle.location.y)  // Flip Y coordinate
            
            DispatchQueue.main.async {
                print("👣 Detected foot position: \(anklePosition)")
                self.footPositionInImage = anklePosition
            }
        }
        
        // Configure request
        request.maximumNumberOfPeopleToDetect = 1
        request.confidenceThreshold = 0.3
    }

    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([request])
        } catch {
            print("❌ Vision error: \(error)")
        }
    }
}
