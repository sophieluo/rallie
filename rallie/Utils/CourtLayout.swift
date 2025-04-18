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
        let topY = screenSize.height * 0.65  
        let bottomY = screenSize.height * 0.88  
        let topInset = screenSize.width * 0.35  
        let bottomInset = screenSize.width * 0.05  
        
        let serviceLineY = topY + (bottomY - topY) * 0.35  
        let serviceLineInset = bottomInset + (topInset - bottomInset) * 0.60  
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
    // Half court is 11.885m long (baseline to net) x 8.23m wide
    // Using coordinate system where (0,0) is at net, Y increases towards baseline
    static let referenceCourtPoints: [CGPoint] = [
        // Main court corners
        CGPoint(x: 0, y: 11.885),      // 0: bottom left (baseline)
        CGPoint(x: 8.23, y: 11.885),   // 1: bottom right (baseline)
        CGPoint(x: 8.23, y: 0),        // 2: top right (net)
        CGPoint(x: 0, y: 0),           // 3: top left (net)
        
        // Service line intersections (6.40m from net)
        CGPoint(x: 0, y: 6.40),        // 4: left service
        CGPoint(x: 8.23, y: 6.40),     // 5: right service
        CGPoint(x: 4.115, y: 6.40),    // 6: center service (back)
        CGPoint(x: 4.115, y: 6.40)     // 7: center service (at service line)
    ]
}

