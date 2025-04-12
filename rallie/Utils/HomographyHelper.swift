import UIKit

class HomographyHelper {
    
    /// Projects a set of known image points to court points — for debugging only
    static func computeHomography(from imagePoints: [CGPoint], to courtPoints: [CGPoint]) -> [CGPoint]? {
        let nsImagePoints = imagePoints.map { NSValue(cgPoint: $0) }
        let nsCourtPoints = courtPoints.map { NSValue(cgPoint: $0) }

        guard let transformed = OpenCVWrapper.computeHomography(from: nsImagePoints, to: nsCourtPoints) else {
            print("❌ Homography computation failed.")
            return nil
        }

        return transformed.map { $0.cgPointValue }
    }

    /// ✅ New: Compute and return the 3x3 matrix we’ll use for projection
    static func computeHomographyMatrix(from imagePoints: [CGPoint], to courtPoints: [CGPoint]) -> [NSNumber]? {
        let nsImagePoints = imagePoints.map { NSValue(cgPoint: $0) }
        let nsCourtPoints = courtPoints.map { NSValue(cgPoint: $0) }

        return OpenCVWrapper.computeHomography(from: nsImagePoints, to: nsCourtPoints)
    }

    /// ✅ New: Project a single screen point using matrix
    static func project(point: CGPoint, using matrix: [NSNumber]) -> CGPoint? {
        guard let projected = OpenCVWrapper.projectPoint(point, usingMatrix: matrix) else {
            return nil
        }
        return projected.cgPointValue
    }
}

