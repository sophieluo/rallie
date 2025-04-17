//
//  CourtLayout.swift
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

// MARK: - CourtLayout.swift
import CoreGraphics

struct CourtLayout {
    static let screenWidth: CGFloat = 844   // landscape iPhone 13
    static let screenHeight: CGFloat = 390

    static func referenceImagePoints(for screenSize: CGSize) -> [CGPoint] {
        let topY = screenSize.height * 0.65  // Keep the same height
        let bottomY = screenSize.height * 0.85
        let topInset = screenSize.width * 0.30  // Decreased for wider angle (was 0.35)
        let bottomInset = screenSize.width * 0.15  // Increased to narrow the base (was 0.03)
        
        // Calculate service line Y position (between top and bottom)
        let serviceLineY = topY + (bottomY - topY) * 0.40
        
        // Calculate service line insets
        let serviceLineInset = bottomInset + (topInset - bottomInset) * 0.70
        let centerX = screenSize.width / 2
        
        return [
            // Main court corners (original 4 points)
            CGPoint(x: bottomInset, y: bottomY),         // 0: bottom left
            CGPoint(x: screenSize.width - bottomInset, y: bottomY), // 1: bottom right
            CGPoint(x: screenWidth - topInset, y: topY),  // 2: top right
            CGPoint(x: topInset, y: topY),               // 3: top left
            
            // Service line intersections
            CGPoint(x: serviceLineInset, y: serviceLineY), // 4: left service
            CGPoint(x: screenSize.width - serviceLineInset, y: serviceLineY), // 5: right service
            CGPoint(x: centerX, y: serviceLineY), // 6: center service (back)
            CGPoint(x: centerX, y: serviceLineY)  // 7: center service (at service line)
        ]
    }

    // Tennis court dimensions in meters
    // Standard singles court is 23.77m x 8.23m
    static let referenceCourtPoints: [CGPoint] = [
        // Main court corners (original 4 points)
        CGPoint(x: 0, y: 0),          // 0: bottom left (baseline)
        CGPoint(x: 8.23, y: 0),       // 1: bottom right (baseline)
        CGPoint(x: 8.23, y: 23.77),   // 2: top right (net)
        CGPoint(x: 0, y: 23.77),      // 3: top left (net)
        
        // Service line intersections (new 4 points)
        CGPoint(x: 0, y: 18.28),      // 4: left service (6.4m from baseline)
        CGPoint(x: 8.23, y: 18.28),   // 5: right service
        CGPoint(x: 4.115, y: 18.28),  // 6: center service (back)
        CGPoint(x: 4.115, y: 18.28)   // 7: center service (at service line)
    ]
}

