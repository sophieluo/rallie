func computeCourtPoints(screenWidth: CGFloat, screenHeight: CGFloat) -> [CGPoint] {
    let topY = screenHeight * 0.40  // Moved even higher
    let bottomY = screenHeight * 0.90
    let topInset = screenWidth * 0.40  // Increased more for even sharper angle
    let bottomInset = screenWidth * 0.08  // Decreased further for wider base
    
    // Calculate service line Y position (between top and bottom)
    let serviceLineY = topY + (bottomY - topY) * 0.25  // Adjusted to be closer to top
    
    // Calculate left sideline equation
    let leftSideM = (topInset - bottomInset) / (topY - bottomY)
    let leftSideB = bottomInset - leftSideM * bottomY
    
    // Calculate right sideline equation
    let rightSideM = ((screenWidth - topInset) - (screenWidth - bottomInset)) / (topY - bottomY)
    let rightSideB = (screenWidth - bottomInset) - rightSideM * bottomY
    
    // Calculate service line intersections with sidelines
    let leftServiceX = leftSideM * serviceLineY + leftSideB
    let rightServiceX = rightSideM * serviceLineY + rightSideB
    
    // Center line X position (average of service line endpoints)
    let centerX = (leftServiceX + rightServiceX) / 2
    
    return [
        // Main court corners (original 4 points)
        CGPoint(x: bottomInset, y: bottomY),         // 0: bottom left
        CGPoint(x: screenWidth - bottomInset, y: bottomY), // 1: bottom right
        CGPoint(x: screenWidth - topInset, y: topY),  // 2: top right
        CGPoint(x: topInset, y: topY),               // 3: top left
        
        // Service line intersections (calculated precisely)
        CGPoint(x: leftServiceX, y: serviceLineY),    // 4: left service
        CGPoint(x: rightServiceX, y: serviceLineY),   // 5: right service
        CGPoint(x: centerX, y: serviceLineY),         // 6: center service
        CGPoint(x: centerX, y: serviceLineY)          // 7: center service (duplicate)
    ]
} 
