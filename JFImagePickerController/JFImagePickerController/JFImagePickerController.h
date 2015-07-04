//
//  JFImagePickerController.h
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JFAssetHelper.h"
#import "JFImageManager.h"

@interface JFImagePickerController : UINavigationController

- (JFImagePickerController *)initWithPreviewIndex:(NSInteger)index;
@property (nonatomic, weak) id pickerDelegate;

/**
 当退出编辑模式时需调用clear，用来清理内存，已选择照片的缓存
 **/
+ (void)clear;
- (UIToolbar *)customToolbar;
- (void)setLeftTitle:(NSString *)title;
- (void)cancel;

- (NSArray *)imagesWithType:(NSInteger)type;
- (NSArray *)assets;

@end

@protocol JFImagePickerDelegate <NSObject>

- (void)imagePickerDidFinished:(JFImagePickerController *)picker;
- (void)imagePickerDidCancel:(JFImagePickerController *)picker;

@end