//
//  FSJCompressionVideoTool.m
//  FSJCompression
//
//  Created by 燕来秋 on 2020/8/17.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import "FSJCompressionVideoTool.h"
#import <AVFoundation/AVFoundation.h>

/*
参考:
https://www.jianshu.com/p/ea502efb0f15
https://github.com/BMWMWM/iOS-AVFoundation-VideoCustomComPressed/blob/master/AVFoundationVideoCustomComPressedDemo/VideoCompress.m
*/

@implementation FSJCompressionVideoTool
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
                 compressComplete:(FSJCompressionCompleteBlock)compressComplete {
    if (!videoUrl) {
        if (compressComplete) {
            compressComplete(NO, nil);
        }
        return;
    }
    NSLog(@"压缩视频 : %@",videoUrl.path);
    NSInteger compressBiteRate = outputBiteRate ? [outputBiteRate integerValue] : 1500 * 1024;
    NSInteger compressFrameRate = outputFrameRate ? [outputFrameRate integerValue] : 30;
    NSInteger compressWidth = outputWidth ? [outputWidth integerValue] : 960;
    NSInteger compressHeight = outputHeight ? [outputHeight integerValue] : 540;
    //取出原视频详细资料
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoUrl];
    //视频时长 S
    CMTime time = [asset duration];
    NSInteger seconds = ceil(time.value/time.timescale);
    if (seconds < 3) {
        if (compressComplete) {
            compressComplete(NO, nil);
        }
        return;
    }
    //压缩前原视频大小MB
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:videoUrl.path error:nil].fileSize;
    float fileSizeMB = fileSize / (1024.0*1024.0);
    //取出asset中的视频文件
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    //压缩前原视频宽高
    NSInteger videoWidth = videoTrack.naturalSize.width;
    NSInteger videoHeight = videoTrack.naturalSize.height;
    
    //压缩前原视频比特率
    NSInteger kbps = videoTrack.estimatedDataRate / 1024;
    //压缩前原视频帧率
//    NSInteger frameRate = [videoTrack nominalFrameRate];
    NSLog(@"原视频大小 : %f videoWidth : %ld videoHeight : %ld",fileSizeMB,(long)videoWidth,(long)videoHeight);
    //原视频比特率小于指定比特率 不压缩 返回原视频
    if (kbps <= (compressBiteRate / 1024)) {
        NSLog(@"原视频的比特率小于压缩的比特率，所以不压缩");
        if (compressComplete) {
            compressComplete(NO, videoUrl);
        }
        return;
    }
    //指定压缩视频沙盒根目录
    NSURL *outPutPathURL = outputURL;
    if (outPutPathURL == nil) {
        NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        //添加文件完整路径
        NSString *outputUrlStr = [[cachesDir stringByAppendingPathComponent:@"videoTest"] stringByAppendingPathExtension:@"mp4"];
        outPutPathURL = [NSURL fileURLWithPath:outputUrlStr];
    }
    
    //如果指定路径下已存在其他文件 先移除指定文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPathURL.path]) {
        BOOL removeSuccess =  [[NSFileManager defaultManager] removeItemAtPath:outPutPathURL.path error:nil];
        if (!removeSuccess) {
            if (compressComplete) {
                compressComplete(NO, videoUrl);
            }
            return;
        }
    }
    //创建视频文件读取者
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    AVAssetReaderTrackOutput *videoOutput = nil;
    if (videoTrack) {
        //从指定文件读取视频
        videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:[self configVideoOutput]];
        //将读取到的视频信息添加到读者队列中
        if ([reader canAddOutput:videoOutput]) {
            [reader addOutput:videoOutput];
        }
    }
    
    //取出原视频中音频详细资料
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetReaderTrackOutput *audioOutput = nil;
    if (audioTrack) {
        //从音频资料中读取音频
        audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:[self configAudioOutput]];
        //将读取到的音频信息添加到读者队列中
        if ([reader canAddOutput:audioOutput]) {
            [reader addOutput:audioOutput];
        }
    }
    
    //视频文件写入者
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outPutPathURL fileType:AVFileTypeMPEG4 error:nil];
    //根据指定配置创建写入的视频文件
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self videoCompressSettingsWithBitRate:compressBiteRate withFrameRate:compressFrameRate withWidth:compressWidth WithHeight:compressHeight withOriginalWidth:videoWidth withOriginalHeight:videoHeight]];
    // 视频方向
    videoInput.transform = videoTrack.preferredTransform;
    
    //根据指定配置创建写入的音频文件
    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:[self audioCompressSettings]];
    if ([writer canAddInput:videoInput]) {
        [writer addInput:videoInput];
    }
    if ([writer canAddInput:audioInput]) {
        [writer addInput:audioInput];
    }
    
    [reader startReading];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    //创建视频写入队列
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Queue", DISPATCH_QUEUE_SERIAL);
    //创建音频写入队列
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Queue", DISPATCH_QUEUE_SERIAL);
    //创建一个线程组
    dispatch_group_t group = dispatch_group_create();
    //进入线程组
    dispatch_group_enter(group);
    
    long long allTimeStamp = asset.duration.value;
    //队列准备好后 usingBlock
    [videoInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([videoInput isReadyForMoreMediaData] && !completedOrFailed) {
            @autoreleasepool {
                CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    [videoInput appendSampleBuffer:sampleBuffer];
                    
                    // 获取进度
                    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    CGFloat progress = (CGFloat)timeStamp.value/(CGFloat)allTimeStamp;
                    if (progressBlock) {
                        progressBlock(progress);
                    }
                    
                    CFRelease(sampleBuffer);
                } else {
                    completedOrFailed = YES;
                    [videoInput markAsFinished];
                    dispatch_group_leave(group);
                }
            }
        }
    }];
    dispatch_group_enter(group);
    //队列准备好后 usingBlock
    [audioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([audioInput isReadyForMoreMediaData] && !completedOrFailed) {
            @autoreleasepool {
                CMSampleBufferRef sampleBuffer = [audioOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    BOOL success = [audioInput appendSampleBuffer:sampleBuffer];
                    CFRelease(sampleBuffer);
                    completedOrFailed = !success;
                } else {
                    completedOrFailed = YES;
                }
            }
        }
        if (completedOrFailed) {
            [audioInput markAsFinished];
            dispatch_group_leave(group);
        }
    }];
    //完成压缩
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if ([reader status] == AVAssetReaderStatusReading) {
            [reader cancelReading];
        }
        
        switch (writer.status) {
            case AVAssetWriterStatusWriting:
            {
                if (progressBlock) {
                    progressBlock(1);
                }
                unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:outPutPathURL.path error:nil].fileSize;
                float fileSizeMB = fileSize / (1024.0*1024.0);
                NSLog(@"视频压缩成功 大小 : %f %@",fileSizeMB,outPutPathURL);
                
                [writer finishWritingWithCompletionHandler:^{
                    if (compressComplete) {
                        compressComplete(YES, outPutPathURL);
                    }
                }];
            }
                break;
            case AVAssetWriterStatusCancelled:
                break;
            case AVAssetWriterStatusFailed:
                NSLog(@"压缩失败 : %@", writer.error);
                break;
            case AVAssetWriterStatusCompleted:
            {
                if (progressBlock) {
                    progressBlock(1);
                }
                
                unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:outPutPathURL.path error:nil].fileSize;
                float fileSizeMB = fileSize / (1024.0*1024.0);
                NSLog(@"视频压缩成功 大小 : %f %@",fileSizeMB,outPutPathURL);
                
                [writer finishWritingWithCompletionHandler:^{
                    if (compressComplete) {
                        compressComplete(YES, outPutPathURL);
                    }
                }];
            }
                break;
            default:
                break;
        }
    });
}

+ (void)compressVideoWithVideoUrl:(NSURL *)videoUrl
                        outputURL:(NSURL *)outputURL
                    progressBlock:(FSJCompressionProgressBlock)progressBlock
                 compressComplete:(FSJCompressionCompleteBlock)compressComplete {
    [self compressVideoWithVideoUrl:videoUrl outputURL:outputURL withBiteRate:nil withFrameRate:nil withVideoWidth:nil withVideoHeight:nil progressBlock:progressBlock compressComplete:compressComplete];
}

+ (NSDictionary *)videoCompressSettingsWithBitRate:(NSInteger)biteRate withFrameRate:(NSInteger)frameRate withWidth:(NSInteger)width WithHeight:(NSInteger)height withOriginalWidth:(NSInteger)originalWidth withOriginalHeight:(NSInteger)originalHeight{
    /*
     * AVVideoAverageBitRateKey： 比特率（码率）每秒传输的文件大小 kbps
     * AVVideoExpectedSourceFrameRateKey：帧率 每秒播放的帧数
     * AVVideoProfileLevelKey：画质水平
     BP-Baseline Profile：基本画质。支持I/P 帧，只支持无交错（Progressive）和CAVLC；
     EP-Extended profile：进阶画质。支持I/P/B/SP/SI 帧，只支持无交错（Progressive）和CAVLC；
     MP-Main profile：主流画质。提供I/P/B 帧，支持无交错（Progressive）和交错（Interlaced），也支持CAVLC 和CABAC 的支持；
     HP-High profile：高级画质。在main Profile 的基础上增加了8×8内部预测、自定义量化、 无损视频编码和更多的YUV 格式；
     **/
    NSInteger returnWidth = originalWidth > originalHeight ? width : height;
    NSInteger returnHeight = originalWidth > originalHeight ? height : width;

    NSDictionary *compressProperties = @{
                                         AVVideoAverageBitRateKey : @(biteRate),
                                         AVVideoExpectedSourceFrameRateKey : @(frameRate),
                                         AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel
                                         };
    if (@available(iOS 11.0, *)) {
        NSDictionary *compressSetting = @{
                                          AVVideoCodecKey : AVVideoCodecTypeH264,
                                          AVVideoWidthKey : @(returnWidth),
                                          AVVideoHeightKey : @(returnHeight),
                                          AVVideoCompressionPropertiesKey : compressProperties,
                                          AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
                                          };
        return compressSetting;
    }else {
        NSDictionary *compressSetting = @{
                                          AVVideoCodecKey : AVVideoCodecH264,
                                          AVVideoWidthKey : @(returnWidth),
                                          AVVideoHeightKey : @(returnHeight),
                                          AVVideoCompressionPropertiesKey : compressProperties,
                                          AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
                                          };
        return compressSetting;
    }
}
//音频设置
+ (NSDictionary *)audioCompressSettings{
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = kAudioChannelBit_Left,
        .mNumberChannelDescriptions = 0,
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *audioCompressSettings = @{
                                            AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                            AVEncoderBitRateKey : @(128000),
                                            AVSampleRateKey : @(44100),
                                            AVNumberOfChannelsKey : @(2),
                                            AVChannelLayoutKey : channelLayoutAsData
                                            };
    return audioCompressSettings;
}
/** 音频解码 */
+ (NSDictionary *)configAudioOutput
{
    NSDictionary *audioOutputSetting = @{
                                         AVFormatIDKey: @(kAudioFormatLinearPCM)
                                         };
    return audioOutputSetting;
}
/** 视频解码 */
+ (NSDictionary *)configVideoOutput
{
    NSDictionary *videoOutputSetting = @{
                                         (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
                                         (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]
                                         };

    return videoOutputSetting;
}

#pragma mark - 生成视频
+ (void)compressVideoWithVideoAsset:(AVURLAsset *)asset
                          outputURL:(NSURL *)outputURL
                       withBiteRate:(NSNumber * _Nullable)outputBiteRate
                      withFrameRate:(NSNumber * _Nullable)outputFrameRate
                     withVideoWidth:(NSNumber * _Nullable)outputWidth
                    withVideoHeight:(NSNumber * _Nullable)outputHeight
                          transform:(CGAffineTransform)transform
                      progressBlock:(FSJCompressionProgressBlock)progressBlock
                   compressComplete:(FSJCompressionCompleteBlock)compressComplete {
    if (!asset) {
        if (compressComplete) {
            compressComplete(NO, nil);
        }
        return;
    }
    NSInteger compressBiteRate = outputBiteRate ? [outputBiteRate integerValue] : 1500 * 1024;
    NSInteger compressFrameRate = outputFrameRate ? [outputFrameRate integerValue] : 30;
    NSInteger compressWidth = outputWidth ? [outputWidth integerValue] : 960;
    NSInteger compressHeight = outputHeight ? [outputHeight integerValue] : 540;
    //视频时长 S
    CMTime time = [asset duration];
    NSInteger seconds = ceil(time.value/time.timescale);
    if (seconds < 3) {
        if (compressComplete) {
            compressComplete(NO, nil);
        }
        return;
    }
    //取出asset中的视频文件
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    //压缩前原视频宽高
    NSInteger videoWidth = videoTrack.naturalSize.width;
    NSInteger videoHeight = videoTrack.naturalSize.height;
    
    //压缩前原视频比特率
    NSInteger kbps = videoTrack.estimatedDataRate / 1024;
    //原视频比特率小于指定比特率 不压缩 返回原视频
    if (kbps <= (compressBiteRate / 1024)) {
        NSLog(@"原视频的比特率小于压缩的比特率，所以不压缩");
        if (compressComplete) {
            compressComplete(NO, nil);
        }
        return;
    }
    //指定压缩视频沙盒根目录
    NSURL *outPutPathURL = outputURL;
    if (outPutPathURL == nil) {
        NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        //添加文件完整路径
        NSString *outputUrlStr = [[cachesDir stringByAppendingPathComponent:@"videoTest"] stringByAppendingPathExtension:@"mp4"];
        outPutPathURL = [NSURL fileURLWithPath:outputUrlStr];
    }
    
    //如果指定路径下已存在其他文件 先移除指定文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPathURL.path]) {
        BOOL removeSuccess =  [[NSFileManager defaultManager] removeItemAtPath:outPutPathURL.path error:nil];
        if (!removeSuccess) {
            if (compressComplete) {
                compressComplete(NO, nil);
            }
            return;
        }
    }
    //创建视频文件读取者
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    AVAssetReaderTrackOutput *videoOutput = nil;
    if (videoTrack) {
        //从指定文件读取视频
        videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:[self configVideoOutput]];
        //将读取到的视频信息添加到读者队列中
        if ([reader canAddOutput:videoOutput]) {
            [reader addOutput:videoOutput];
        }
    }
    
    //取出原视频中音频详细资料
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetReaderTrackOutput *audioOutput = nil;
    if (audioTrack) {
        //从音频资料中读取音频
        audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:[self configAudioOutput]];
        //将读取到的音频信息添加到读者队列中
        if ([reader canAddOutput:audioOutput]) {
            [reader addOutput:audioOutput];
        }
    }
    
    //视频文件写入者
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outPutPathURL fileType:AVFileTypeMPEG4 error:nil];
    //根据指定配置创建写入的视频文件
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self videoCompressSettingsWithBitRate:compressBiteRate withFrameRate:compressFrameRate withWidth:compressWidth WithHeight:compressHeight withOriginalWidth:videoWidth withOriginalHeight:videoHeight]];
    // 视频方向
    videoInput.transform = transform;//videoTrack.preferredTransform;
    
    //根据指定配置创建写入的音频文件
    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:[self audioCompressSettings]];
    if ([writer canAddInput:videoInput]) {
        [writer addInput:videoInput];
    }
    if ([writer canAddInput:audioInput]) {
        [writer addInput:audioInput];
    }
    
    [reader startReading];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    //创建视频写入队列
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Queue", DISPATCH_QUEUE_SERIAL);
    //创建音频写入队列
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Queue", DISPATCH_QUEUE_SERIAL);
    //创建一个线程组
    dispatch_group_t group = dispatch_group_create();
    //进入线程组
    dispatch_group_enter(group);
    
    NSLog(@"开始压缩视频");
    CGFloat allSecond = (CGFloat)asset.duration.value / (CGFloat)asset.duration.timescale;
    //队列准备好后 usingBlock
    [videoInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([videoInput isReadyForMoreMediaData] && !completedOrFailed) {
            @autoreleasepool {
                CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    [videoInput appendSampleBuffer:sampleBuffer];
                    
                    // 获取进度
                    CMTime timeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    CGFloat second = (CGFloat)timeStamp.value / (CGFloat)timeStamp.timescale;
                    CGFloat progress = (CGFloat)second/(CGFloat)allSecond;
                    if (progressBlock) {
                        progressBlock(progress);
                    }
                    
                    CFRelease(sampleBuffer);
                } else {
                    completedOrFailed = YES;
                    [videoInput markAsFinished];
                    dispatch_group_leave(group);
                }
            }
        }
    }];
    dispatch_group_enter(group);
    //队列准备好后 usingBlock
    [audioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([audioInput isReadyForMoreMediaData] && !completedOrFailed) {
            @autoreleasepool {
                CMSampleBufferRef sampleBuffer = [audioOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    BOOL success = [audioInput appendSampleBuffer:sampleBuffer];
                    CFRelease(sampleBuffer);
                    completedOrFailed = !success;
                } else {
                    completedOrFailed = YES;
                }
            }
        }
        if (completedOrFailed) {
            [audioInput markAsFinished];
            dispatch_group_leave(group);
        }
    }];
    //完成压缩
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if ([reader status] == AVAssetReaderStatusReading) {
            [reader cancelReading];
        }
        
        switch (writer.status) {
            case AVAssetWriterStatusWriting:
            {
                if (progressBlock) {
                    progressBlock(1);
                }
                unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:outPutPathURL.path error:nil].fileSize;
                float fileSizeMB = fileSize / (1024.0*1024.0);
                NSLog(@"视频压缩成功 大小 : %f %@",fileSizeMB,outPutPathURL);
                
                [writer finishWritingWithCompletionHandler:^{
                    if (compressComplete) {
                        compressComplete(YES, outPutPathURL);
                    }
                }];
            }
                break;
            case AVAssetWriterStatusCancelled:
                break;
            case AVAssetWriterStatusFailed:
                NSLog(@"压缩失败 : %@", writer.error);
                break;
            case AVAssetWriterStatusCompleted:
            {
                if (progressBlock) {
                    progressBlock(1);
                }
                
                unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:outPutPathURL.path error:nil].fileSize;
                float fileSizeMB = fileSize / (1024.0*1024.0);
                NSLog(@"视频压缩成功 大小 : %f %@",fileSizeMB,outPutPathURL);
                
                [writer finishWritingWithCompletionHandler:^{
                    if (compressComplete) {
                        compressComplete(YES, outPutPathURL);
                    }
                }];
            }
                break;
            default:
                break;
        }
    });
}

+ (void)compressVideoWithVideoAsset:(AVURLAsset *)asset
                          outputURL:(NSURL *)outputURL
                          transform:(CGAffineTransform)transform
                      progressBlock:(FSJCompressionProgressBlock)progressBlock
                   compressComplete:(FSJCompressionCompleteBlock)compressComplete {
    [self compressVideoWithVideoAsset:asset outputURL:outputURL withBiteRate:nil withFrameRate:nil withVideoWidth:nil withVideoHeight:nil transform:transform progressBlock:progressBlock compressComplete:compressComplete];
}

@end
