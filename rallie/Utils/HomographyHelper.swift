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

    /// ✅ New: Compute and return the 3x3 matrix we'll use for projection
    static func computeHomographyMatrix(from imagePoints: [CGPoint], to courtPoints: [CGPoint]) -> [NSNumber]? {
        // Validate input points
        guard imagePoints.count == 8, courtPoints.count == 8 else {
            print("❌ Invalid number of points for homography")
            return nil
        }
        
        print("📐 Computing homography with:")
        print("Image points: \(imagePoints)")
        print("Court points: \(courtPoints)")
        
        let nsImagePoints = imagePoints.map { NSValue(cgPoint: $0) }
        let nsCourtPoints = courtPoints.map { NSValue(cgPoint: $0) }

        guard let matrix = OpenCVWrapper.computeHomography(from: nsImagePoints, to: nsCourtPoints) else {
            print("❌ Homography computation failed")
            return nil
        }
        
        print("✅ Homography matrix computed: \(matrix)")
        return matrix
    }

    /// ✅ New: Project a single screen point using matrix
    static func project(point: CGPoint, using matrix: [NSNumber]) -> CGPoint? {
        guard matrix.count == 9 else {
            print("❌ Invalid homography matrix size")
            return nil
        }
        
        guard let projected = OpenCVWrapper.projectPoint(point, usingMatrix: matrix) else {
            print("❌ Point projection failed for point: \(point)")
            return nil
        }
        
        print("📍 Projected point \(point) to \(projected.cgPointValue)")
        return projected.cgPointValue
    }
}

