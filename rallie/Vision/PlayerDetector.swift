//
//  PlayerDetector.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

import Vision
import UIKit

class PlayerDetector: ObservableObject {
    @Published var boundingBox: CGRect = .zero

    private var request: VNDetectHumanRectanglesRequest!
    private var sequenceHandler = VNSequenceRequestHandler()

    init() {
        request = VNDetectHumanRectanglesRequest { [weak self] request, error in
            guard let results = request.results as? [VNHumanObservation],
                  let first = results.first else {
                DispatchQueue.main.async {
                    self?.boundingBox = .zero
                }
                return
            }

            DispatchQueue.main.async {
                self?.boundingBox = first.boundingBox
            }
        }
    }

    func processPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: .right)

        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("❌ Vision error: \(error)")
        }
    }
}
