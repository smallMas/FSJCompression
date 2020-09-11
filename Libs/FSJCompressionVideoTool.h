//
//  FSJCompressionVideoTool.h
//  FSJCompression
//
//  Created by 燕来秋 on 2020/8/17.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSJCompressionBlockHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSJCompressionVideoTool : NSObject


/*
 * 自定义视频压缩
 * videoUrl 原视频url路径 必传
 * outputURL 输出url路径，不传默认/Library/Caches/videoTest.mp4
 * outputBiteRate 压缩视频至指定比特率(bps) 可传nil 默认1500kbps
 * outputFrameRate 压缩视频至指定帧率 可传nil 默认30fps
 * outputWidth 压缩视频至指定宽度 可传nil 默认960
 * outputWidth 压缩视频至指定高度 可传nil 默认540
 * progressBlock 压缩进度回调
 * compressComplete 压缩后的视频信息回调 (id responseObjc) 可自行打印查看
 **/
+ (void)compressVideoWithVideoUrl:(NSURL *)videoUrl
                        outputURL:(NSURL *)outputURL
                     withBiteRate:(NSNumber * _Nullable)outputBiteRate
                    withFrameRate:(NSNumber * _Nullable)outputFrameRate
                   withVideoWidth:(NSNumber * _Nullable)outputWidth
                  withVideoHeight:(NSNumber * _Nullable)outputHeight
                    progressBlock:(FSJCompressionProgressBlock)progressBlock
                 compressComplete:(FSJCompressionCompleteBlock)compressComplete;

/*
* 自定义视频压缩 默认1500kbps 默认30fps 默认960 默认540
* videoUrl 原视频url路径 必传
* outputURL 输出url路径，不传默认/Library/Caches/videoTest.mp4
* progressBlock 压缩进度回调
* compressComplete 压缩后的视频信息回调 (id responseObjc) 可自行打印查看
**/
+ (void)compressVideoWithVideoUrl:(NSURL *)videoUrl
                        outputURL:(NSURL *)outputURL
                           progressBlock:(FSJCompressionProgressBlock)progressBlock
                        compressComplete:(FSJCompressionCompleteBlock)compressComplete;

#pragma mark - 生成视频
/// 生成视频并压缩
/// @param asset AVAsset
/// @param outputURL 输出url路径，不传默认/Library/Caches/videoTest.mp4
/// @param outputBiteRate 压缩视频至指定比特率(bps) 可传nil 默认1500kbps
/// @param outputFrameRate 压缩视频至指定帧率 可传nil 默认30fps
/// @param outputWidth 压缩视频至指定宽度 可传nil 默认960
/// @param outputHeight 压缩视频至指定高度 可传nil 默认540
/// @param transform 方向
/// @param progressBlock 进度回调
/// @param compressComplete 视频信息回调 (id responseObjc) 可自行打印查看
+ (void)compressVideoWithVideoAsset:(AVURLAsset *)asset
                          outputURL:(NSURL *)outputURL
                       withBiteRate:(NSNumber * _Nullable)outputBiteRate
                      withFrameRate:(NSNumber * _Nullable)outputFrameRate
                     withVideoWidth:(NSNumber * _Nullable)outputWidth
                    withVideoHeight:(NSNumber * _Nullable)outputHeight
                          transform:(CGAffineTransform)transform
                      progressBlock:(FSJCompressionProgressBlock)progressBlock
                   compressComplete:(FSJCompressionCompleteBlock)compressComplete;

/// 生成视频并压缩 默认1500kbps 默认30fps 默认960 默认540
/// @param asset AVAsset
/// @param outputURL 输出url路径，不传默认/Library/Caches/videoTest.mp4
/// @param transform 方向
/// @param progressBlock 进度回调
/// @param compressComplete 视频信息回调 (id responseObjc) 可自行打印查看
+ (void)compressVideoWithVideoAsset:(AVURLAsset *)asset
                          outputURL:(NSURL *)outputURL
                          transform:(CGAffineTransform)transform
                      progressBlock:(FSJCompressionProgressBlock)progressBlock
                   compressComplete:(FSJCompressionCompleteBlock)compressComplete;
@end

NS_ASSUME_NONNULL_END
