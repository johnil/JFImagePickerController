//
//  JFPhotoView.h
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface JFPhotoView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, weak) id photoDelegate;

- (void)reloadRotate;
- (void)reset;
- (void)clearMemory;
- (void)loadImage:(ALAsset *)asset;

@end

@protocol JFPhotoDelegate <NSObject>

- (void)tap;

@end