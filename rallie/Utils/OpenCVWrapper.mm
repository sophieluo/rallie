//
//  OpenCVWrapper.mm
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

#import "OpenCVWrapper.h"

#ifdef __OBJC__
#undef NO
#endif

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

using namespace cv;

@implementation OpenCVWrapper

+ (nullable NSArray<NSNumber *> *)computeHomographyFrom:(NSArray<NSValue *> *)imagePoints
                                                     to:(NSArray<NSValue *> *)courtPoints {
    if (imagePoints.count != 8 || courtPoints.count != 8) return nil;

    std::vector<cv::Point2f> src, dst;
    for (int i = 0; i < 8; i++) {
        CGPoint sp = [imagePoints[i] CGPointValue];
        CGPoint dp = [courtPoints[i] CGPointValue];
        
        // Use raw image points (no normalization needed)
        src.push_back(cv::Point2f(sp.x, sp.y));
        
        // Court points in meters
        dst.push_back(cv::Point2f(dp.x, dp.y));
    }

    cv::Mat H = cv::findHomography(src, dst, cv::RANSAC);
    if (H.empty()) return nil;

    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:9];
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            double value = H.at<double>(i, j);
            [result addObject:@(value)];
        }
    }

    return result;
}


+ (nullable NSValue *)projectPoint:(CGPoint)point usingMatrix:(NSArray<NSNumber *> *)matrix {
    if (matrix.count != 9) return nil;

    Mat H(3, 3, CV_64F);  // Changed to double precision
    for (int i = 0; i < 9; ++i) {
        double value = [matrix[i] doubleValue];
        H.at<double>(i / 3, i % 3) = value;
    }

    std::vector<Point2f> input = { Point2f(point.x, point.y) };
    std::vector<Point2f> output;

    perspectiveTransform(input, output, H);
    if (output.empty()) return nil;

    return [NSValue valueWithCGPoint:CGPointMake(output[0].x, output[0].y)];
}

+ (UIImage *)cannyEdgeDetectionWithImage:(UIImage *)image
                          lowerThreshold:(double)lowerThreshold
                          upperThreshold:(double)upperThreshold {
    // Convert UIImage to cv::Mat
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (RGBA)
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                   cols,
                                                   rows,
                                                   8,
                                                   mat.step[0],
                                                   colorSpace,
                                                   kCGImageAlphaNoneSkipLast |
                                                   kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    // Convert to grayscale
    cv::Mat grayMat;
    cv::cvtColor(mat, grayMat, cv::COLOR_RGBA2GRAY);
    
    // Apply Gaussian blur to reduce noise
    cv::Mat blurredMat;
    cv::GaussianBlur(grayMat, blurredMat, cv::Size(5, 5), 1.5);
    
    // Apply Canny edge detection
    cv::Mat edgesMat;
    cv::Canny(blurredMat, edgesMat, lowerThreshold, upperThreshold);
    
    // Convert back to RGBA for UIImage
    cv::Mat resultMat;
    cv::cvtColor(edgesMat, resultMat, cv::COLOR_GRAY2RGBA);
    
    // Convert cv::Mat back to UIImage
    NSData *data = [NSData dataWithBytes:resultMat.data length:resultMat.elemSize() * resultMat.total()];
    
    CGColorSpaceRef colorSpace2 = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cols,
                                       rows,
                                       8,
                                       8 * 4,
                                       resultMat.step[0],
                                       colorSpace2,
                                       kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       false,
                                       kCGRenderingIntentDefault);
    
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace2);
    
    return resultImage;
}

+ (NSArray<NSValue *> *)detectCourtCornersInImage:(UIImage *)image
                                   lowerThreshold:(double)lowerThreshold
                                   upperThreshold:(double)upperThreshold {
    // Convert UIImage to cv::Mat
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (RGBA)
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                   cols,
                                                   rows,
                                                   8,
                                                   mat.step[0],
                                                   colorSpace,
                                                   kCGImageAlphaNoneSkipLast |
                                                   kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    // Convert to grayscale
    cv::Mat grayMat;
    cv::cvtColor(mat, grayMat, cv::COLOR_RGBA2GRAY);
    
    // Apply Gaussian blur to reduce noise
    cv::Mat blurredMat;
    cv::GaussianBlur(grayMat, blurredMat, cv::Size(5, 5), 1.5);
    
    // Apply Canny edge detection
    cv::Mat edgesMat;
    cv::Canny(blurredMat, edgesMat, lowerThreshold, upperThreshold);
    
    // Find contours
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edgesMat, contours, hierarchy, cv::RETR_LIST, cv::CHAIN_APPROX_SIMPLE);
    
    // Filter contours by size
    std::vector<std::vector<cv::Point>> filteredContours;
    for (const auto& contour : contours) {
        double area = cv::contourArea(contour);
        // Filter out very small contours
        if (area > 1000) {
            filteredContours.push_back(contour);
        }
    }
    
    // Sort contours by area (largest first)
    std::sort(filteredContours.begin(), filteredContours.end(), 
              [](const std::vector<cv::Point>& c1, const std::vector<cv::Point>& c2) {
                  return cv::contourArea(c1) > cv::contourArea(c2);
              });
    
    // Get the largest contour (likely the court)
    if (filteredContours.empty()) {
        return nil; // No suitable contours found
    }
    
    // Get the largest contour
    std::vector<cv::Point> largestContour = filteredContours[0];
    
    // Approximate the contour to simplify it
    std::vector<cv::Point> approxCurve;
    double epsilon = 0.02 * cv::arcLength(largestContour, true);
    cv::approxPolyDP(largestContour, approxCurve, epsilon, true);
    
    // We need exactly 4 corners for a court
    if (approxCurve.size() != 4) {
        // If we don't have exactly 4 corners, try to find the 4 extreme points
        cv::Point topLeft = cv::Point(cols, rows);
        cv::Point topRight = cv::Point(0, rows);
        cv::Point bottomLeft = cv::Point(cols, 0);
        cv::Point bottomRight = cv::Point(0, 0);
        
        for (const auto& point : largestContour) {
            // Top-left: minimize x+y
            if (point.x + point.y < topLeft.x + topLeft.y) {
                topLeft = point;
            }
            
            // Top-right: maximize x-y
            if (point.x - point.y > topRight.x - topRight.y) {
                topRight = point;
            }
            
            // Bottom-left: minimize x-y
            if (point.x - point.y < bottomLeft.x - bottomLeft.y) {
                bottomLeft = point;
            }
            
            // Bottom-right: maximize x+y
            if (point.x + point.y > bottomRight.x + bottomRight.y) {
                bottomRight = point;
            }
        }
        
        approxCurve = {topLeft, topRight, bottomRight, bottomLeft};
    }
    
    // Sort corners in clockwise order: top-left, top-right, bottom-right, bottom-left
    std::vector<cv::Point> sortedCorners(4);
    
    // Calculate the center of the contour
    cv::Moments moments = cv::moments(approxCurve);
    cv::Point center(moments.m10 / moments.m00, moments.m01 / moments.m00);
    
    // Sort corners based on their angle from the center
    std::sort(approxCurve.begin(), approxCurve.end(), [center](const cv::Point& a, const cv::Point& b) {
        return std::atan2(a.y - center.y, a.x - center.x) < std::atan2(b.y - center.y, b.x - center.x);
    });
    
    // Convert to NSArray of NSValue (CGPoint)
    NSMutableArray<NSValue *> *corners = [NSMutableArray arrayWithCapacity:4];
    for (const auto& point : approxCurve) {
        [corners addObject:[NSValue valueWithCGPoint:CGPointMake(point.x, point.y)]];
    }
    
    return corners;
}

@end
