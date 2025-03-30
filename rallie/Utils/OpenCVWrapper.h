//
//  OpenCVWrapper.h
//  rallie
//
//  Created by Xiexiao_Luo on 3/29/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (nullable NSArray<NSValue *> *)computeHomographyFrom:(NSArray<NSValue *> *)srcPoints
                                                     to:(NSArray<NSValue *> *)dstPoints;

@end
