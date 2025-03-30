import UIKit

class HomographyHelper {
    /// Uses the Objective-C++ wrapper to compute homography and transform points
    static func computeHomography(from imagePoints: [CGPoint], to courtPoints: [CGPoint]) -> [CGPoint]? {
        // Convert [CGPoint] to [NSValue]
        let nsImagePoints = imagePoints.map { NSValue(cgPoint: $0) }
        let nsCourtPoints = courtPoints.map { NSValue(cgPoint: $0) }

        // Call into OpenCVWrapper
        guard let transformed = OpenCVWrapper.computeHomography(from: nsImagePoints, to: nsCourtPoints) else {
            print("❌ Homography computation failed.")
            return nil
        }

        // Convert back from [NSValue] to [CGPoint]
        return transformed.map { $0.cgPointValue }
    }
}
