//
//  FSJCompressionBlockHeader.h
//  FSJCompression
//
//  Created by 燕来秋 on 2020/8/17.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef void (^ FSJCompressionProgressBlock)(CGFloat progress);
typedef void (^ FSJCompressionCompleteBlock)(BOOL isSuccess, NSURL * _Nullable outputURL);
