//
//  FSJCompressionImageTool.h
//  FSJCompression
//
//  Created by 燕来秋 on 2020/9/4.
//  Copyright © 2020 燕来秋. All rights reserved.
//  图片压缩

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSJCompressionImageTool : NSObject

/// 图片尺寸压缩
/// @param image 图片
/// @param size 压缩尺寸
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
