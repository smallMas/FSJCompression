//
//  FSVideoImageTool.m
//  FSGPUImage
//
//  Created by 燕来秋 on 2020/7/14.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import "FSVideoImageTool.h"
#import <Photos/Photos.h>
#import "FSPathTool.h"

@implementation FSVideoImageTool

+ (void)getVideoURL:(PHAsset *)phAsset block:(void (^)(NSURL *URL))block {
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    __block NSURL *url = nil;
    __weak typeof(self) wself = self;
    [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset*)asset;
            NSNumber *size;
            [urlAsset.URL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
            NSData *data = [[NSData alloc] initWithContentsOfURL:urlAsset.URL];
            url = [wself getVideoFilePath];
            BOOL is = [[NSFileManager defaultManager] createFileAtPath:url.path contents:data attributes:nil];
            if (is) {
                NSLog(@"视频保存沙盒成功");
                if (block) {
                    block(url);
                }
            }else {
                NSLog(@"视频保存沙盒失败");
                if (block) {
                    block(nil);
                }
            }
        }
    }];
}

+ (NSURL *)getVideoFilePath {
    return [self getVideoFilePathWithName:nil];
}

+ (NSURL *)getVideoFilePathWithName:(NSString *)name {
    NSString *videoFolder = [FSPathTool folderPathWithName:DNRecordTmpFloder];
    NSString *nameString = name;
    if (nameString == nil) {
        NSString *nowTimeStr = [FSPathTool createName];
        nameString = [NSString stringWithFormat:@"%@.mp4",nowTimeStr];
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", videoFolder, nameString];
    return [NSURL fileURLWithPath:urlString];
}

@end
