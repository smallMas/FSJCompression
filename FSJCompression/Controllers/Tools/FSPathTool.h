//
//  FSPathTool.h
//  FSGPUImage
//
//  Created by 燕来秋 on 2020/7/14.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DNRecordTmpFloder @"FS_Record_Tmp"
#define DNRecordCompoundFolder @"FS_Video_Compound"

NS_ASSUME_NONNULL_BEGIN

@interface FSPathTool : NSObject

// 创建/获取Document下的目录
+ (NSString *)folderPathWithName:(NSString *)name;

/// 目录下的文件
/// @param name 目录名字
/// @param fileName 文件名字 (可为空)
+ (NSString *)folderVideoPathWithName:(NSString *)name fileName:(NSString * __nullable)fileName;

// 名字
+ (NSString *)createName;



@end

NS_ASSUME_NONNULL_END
