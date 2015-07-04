//
//  JFImageManager.h
//  JFImagePickerController
//
//  Created by Johnil on 15/7/4.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface JFImageManager : NSObject

+ (JFImageManager *)sharedManager;
- (void)clearMem;
- (void)startCahcePhotoThumbWithSize:(CGSize)size;
- (void)thumbWithAsset:(ALAsset *)asset
         resultHandler:(void (^)(UIImage *result))resultHandler;
- (void)imageWithAsset:(ALAsset *)asset
         resultHandler:(void (^)(CGImageRef imageRef, BOOL longImage))resultHandler;

@end
