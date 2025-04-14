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

    private var request: VNDetectHumanRectanglesRequest!
    private var sequenceHandler = VNSequenceRequestHandler()

    init() {
        request = VNDetectHumanRectanglesRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNHumanObservation],
                  let first = results.first else {
                DispatchQueue.main.async {
                    self?.footPositionInImage = nil
                }
                return
            }

            let bbox = first.boundingBox
            let centerX = bbox.origin.x + bbox.width / 2
            let bottomY = bbox.origin.y  // 👣 This is the Y at the bottom of the box

            // Vision's origin is bottom-left, but we flip Y to top-left coordinate system
            let flippedY = 1.0 - bottomY

            DispatchQueue.main.async {
                self.footPositionInImage = CGPoint(x: centerX, y: flippedY)
            }
        }
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
