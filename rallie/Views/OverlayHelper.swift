func computeCourtPoints(screenWidth: CGFloat, screenHeight: CGFloat) -> [CGPoint] {
    let topY = screenHeight * 0.40  // Moved even higher
    let bottomY = screenHeight * 0.85
    let topInset = screenWidth * 0.40  // Increased more for even sharper angle
    let bottomInset = screenWidth * 0.08  // Decreased further for wider base
    
    // Calculate service line Y position (between top and bottom)
    let serviceLineY = topY + (bottomY - topY) * 0.25  // Adjusted to be closer to top
    
    // Calculate service line insets (proportional between top and bottom insets)
    let serviceLineInset = bottomInset + (topInset - bottomInset) * 0.75  // Adjusted for sharper angle
    
    // Center line X positions
    let centerX = screenWidth / 2
    
    return [
        // Main court corners (original 4 points)
        CGPoint(x: bottomInset, y: bottomY),         // 0: bottom left
        CGPoint(x: screenWidth - bottomInset, y: bottomY), // 1: bottom right
        CGPoint(x: screenWidth - topInset, y: topY),  // 2: top right
        CGPoint(x: topInset, y: topY),               // 3: top left
        
        // Service line intersections
        CGPoint(x: serviceLineInset, y: serviceLineY), // 4: left service
        CGPoint(x: screenWidth - serviceLineInset, y: serviceLineY), // 5: right service
        CGPoint(x: centerX, y: serviceLineY), // 6: center service (back)
        CGPoint(x: centerX, y: serviceLineY)  // 7: center service (at service line)
    ]
} 
