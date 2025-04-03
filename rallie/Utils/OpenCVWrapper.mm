//
//  OpenCVWrapper.m
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

+ (nullable NSArray<NSValue *> *)computeHomographyFrom:(NSArray<NSValue *> *)imagePoints
                                                     to:(NSArray<NSValue *> *)courtPoints {
    if (imagePoints.count != 4 || courtPoints.count != 4) return nil;

    std::vector<Point2f> src, dst;
    for (int i = 0; i < 4; i++) {
        CGPoint sp = [imagePoints[i] CGPointValue];
        CGPoint dp = [courtPoints[i] CGPointValue];
        src.push_back(Point2f(sp.x, sp.y));
        dst.push_back(Point2f(dp.x, dp.y));
    }

    Mat H = findHomography(src, dst);
    if (H.empty()) return nil;

    NSMutableArray *result = [NSMutableArray array];
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            float value = (float)H.at<double>(i, j);
            CGPoint point = CGPointMake(j, value); // encode value as .y
            [result addObject:[NSValue valueWithCGPoint:point]];
        }
    }

    return result;
}

+ (nullable NSValue *)projectPoint:(CGPoint)point usingMatrix:(NSArray<NSNumber *> *)matrix {
    if (matrix.count != 9) return nil;

    Mat H(3, 3, CV_32F);
    for (int i = 0; i < 9; ++i) {
        float value = [matrix[i] floatValue];
        H.at<float>(i / 3, i % 3) = value;
    }

    std::vector<Point2f> input = { Point2f(point.x, point.y) };
    std::vector<Point2f> output;

    perspectiveTransform(input, output, H);
    if (output.empty()) return nil;

    return [NSValue valueWithCGPoint:CGPointMake(output[0].x, output[0].y)];
}

@end
