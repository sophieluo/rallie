//
//  OpenCVWrapper.m
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

#import "OpenCVWrapper.h"
#import <Foundation/Foundation.h>

#ifdef __cplusplus
#import <opencv2/core.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/calib3d.hpp>
#import <opencv2/calib3d.hpp>
#import <opencv2/core/core.hpp>
#endif

using namespace cv;

@implementation OpenCVWrapper

+ (NSArray<NSValue *> *)computeHomographyFrom:(NSArray<NSValue *> *)imagePoints
                                            to:(NSArray<NSValue *> *)courtPoints
{
    CV_Assert(imagePoints.count == 4 && courtPoints.count == 4);

    Mat src(4, 1, CV_32FC2);
    Mat dst(4, 1, CV_32FC2);

    for (int i = 0; i < 4; i++) {
        CGPoint srcPt = [imagePoints[i] CGPointValue];
        CGPoint dstPt = [courtPoints[i] CGPointValue];

        src.at<Vec2f>(i, 0) = Vec2f(srcPt.x, srcPt.y);
        dst.at<Vec2f>(i, 0) = Vec2f(dstPt.x, dstPt.y);
    }

    Mat H = findHomography(src, dst);

    NSMutableArray *result = [NSMutableArray array];
    for (int r = 0; r < H.rows; r++) {
        for (int c = 0; c < H.cols; c++) {
            float val = H.at<double>(r, c);
            [result addObject:[NSValue valueWithCGPoint:CGPointMake(c, val)]];
        }
    }
    return result;
}

@end
