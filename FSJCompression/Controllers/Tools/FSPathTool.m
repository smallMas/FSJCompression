//
//  FSPathTool.m
//  FSGPUImage
//
//  Created by 燕来秋 on 2020/7/14.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import "FSPathTool.h"

@implementation FSPathTool

#pragma mark - 路径
+ (NSString *)rootPath {
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return cacheFolder;
}

+ (NSString *)folderPathWithName:(NSString *)folder {
    NSString *path = [NSString stringWithFormat:@"%@/%@",[self rootPath],folder];
    if (folder == nil) {
        path = [self rootPath];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

+ (NSString *)folderVideoPathWithName:(NSString *)name fileName:(NSString *)fileName {
    NSString *videoFolder = [self folderPathWithName:name];
    NSString *nameString = fileName;
    if (nameString == nil) {
        NSString *nowTimeStr = [self createName];
        nameString = [NSString stringWithFormat:@"%@.mp4",nowTimeStr];
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", videoFolder, nameString];
    return urlString;
}

+ (NSString *)createName {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    return nowTimeStr;
}

@end
