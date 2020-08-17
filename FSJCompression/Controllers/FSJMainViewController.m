//
//  FSJMainViewController.m
//  FSJCompression
//
//  Created by 燕来秋 on 2020/8/17.
//  Copyright © 2020 燕来秋. All rights reserved.
//

#import "FSJMainViewController.h"
#import "TZImagePickerController.h"
#import "FSVideoImageTool.h"
#import "FSPathTool.h"
#import "FSJCompression.h"

@interface FSJMainViewController ()

@property (nonatomic, strong) UIButton *albumBtn;

@end

@implementation FSJMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.albumBtn];
    
    [self.albumBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(50);
        make.center.mas_equalTo(self.view);
    }];
}

- (UIButton *)albumBtn {
    if (!_albumBtn) {
        _albumBtn = [UIButton fsj_createWithType:UIButtonTypeCustom target:self action:@selector(albumAction:)];
        [_albumBtn setBackgroundColor:[UIColor redColor]];
        [_albumBtn setTitle:@"相册" forState:UIControlStateNormal];
        [_albumBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return _albumBtn;
}

- (void)albumAction:(id)sender {
    TZImagePickerController *_imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
    // 2. Set the appearance
    // 2. 在这里设置imagePickerVc的外观
    
    // 3. 设置是否可以选择视频/图片/原图
    _imagePickerVc.allowPickingVideo = YES; // 是否允许选择视频
    _imagePickerVc.allowPickingImage = NO; //是否允许选择图片
    _imagePickerVc.allowPickingOriginalPhoto = NO;// 是否允许选择原片
    _imagePickerVc.allowPickingGif = NO;  //是否允许选择GIF
    _imagePickerVc.allowCrop = YES;
    _imagePickerVc.timeout = 2;
    _imagePickerVc.cropRect = CGRectMake(0, 0, FSJSCREENWIDTH, FSJSCREENWIDTH);
    _imagePickerVc.cropRectPortrait = CGRectMake(0, 0, FSJSCREENWIDTH, FSJSCREENWIDTH);
    // 4. 照片排列按修改时间升序
    _imagePickerVc.sortAscendingByModificationDate = YES;
    _imagePickerVc.showSelectBtn = NO;
    _imagePickerVc.needCircleCrop = NO;
//    _imagePickerVc.photoWidth = SCREENWIDTH*2;
    _imagePickerVc.circleCropRadius = FSJSCREENWIDTH/2;
    _imagePickerVc.statusBarStyle = UIStatusBarStyleDefault;
//    _imagePickerVc.barItemTextColor = DSColorFromHex(0x323232);
//    _imagePickerVc.naviTitleColor = DSColorFromHex(0x323232);
    _imagePickerVc.navigationItem.leftBarButtonItem.tintColor = [UIColor blackColor];

    _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
//           _imagePickerVc.navigationBar.tintColor = DSColorFromHex(0x323232);
           UIBarButtonItem *tzBarItem, *BarItem;
               tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
               BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
    //设置返回图片，防止图片被渲染变蓝，以原图显示
    _imagePickerVc.navigationBar.backIndicatorTransitionMaskImage = [[UIImage imageNamed:@"public_icon_white_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    _imagePickerVc.navigationBar.backIndicatorImage = [[UIImage imageNamed:@"public_icon_white_back"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
           NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
           [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    _imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:_imagePickerVc animated:YES completion:nil];
}

#pragma mark - TZImagePickerControllerDelegate
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset {
    NSLog(@"asset >>> %@",asset);
    
    FSJ_WEAK_SELF
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [FSVideoImageTool getVideoURL:asset block:^(NSURL * _Nonnull URL) {
            FSJ_STRONG_SELF
            dispatch_async(dispatch_get_main_queue(), ^{
                if (URL) {
                    [self compressionURL:URL];
                }
            });
        }];
    });
}

- (void)compressionURL:(NSURL *)URL {
    NSString *outPutPath = [FSPathTool folderVideoPathWithName:DNRecordCompoundFolder fileName:nil];
    NSURL *outPutURL = [NSURL fileURLWithPath:outPutPath];
    [FSJCompressionVideoTool compressVideoWithVideoUrl:URL outputURL:outPutURL withBiteRate:nil withFrameRate:nil withVideoWidth:nil withVideoHeight:nil progressBlock:^(CGFloat progress) {
        NSLog(@"progress >>> %f",progress);
    } compressComplete:^(BOOL isSuccess, NSURL * _Nullable outputURL) {
        NSLog(@"isSuccess >>> %d outputURL : %@",isSuccess,outputURL);
    }];
}

@end
