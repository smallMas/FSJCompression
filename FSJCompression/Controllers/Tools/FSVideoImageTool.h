//
//  FSVideoImageTool.h
//  FSGPUImage
//
//  Created by 燕来秋 on 2020/7/14.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSVideoImageTool : NSObject

+ (void)getVideoURL:(PHAsset *)phAsset block:(void (^)(NSURL *URL))block;

@end

NS_ASSUME_NONNULL_END
