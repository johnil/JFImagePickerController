//
//  JFPhotoView.m
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import "JFPhotoView.h"
#import "JFAssetHelper.h"
#import "JFImageManager.h"

@implementation JFPhotoView {
    BOOL needLayout;
    NSMutableArray *splitImage;
    CGImageRef originImageRef;
    float splitHeight;
    BOOL zooming;
    CGSize originSize;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        needLayout = YES;
        self.delegate = self;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        _imageView = [[UIImageView alloc] initWithImage:nil];
        _imageView.backgroundColor = [UIColor clearColor];
        _imageView.frame = CGRectZero;
        _imageView.userInteractionEnabled = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        
        self.maximumZoomScale = 1;
        self.minimumZoomScale = .1;
        self.zoomScale = 1;
        self.contentSize = CGSizeMake(0, 0);
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        tap.numberOfTapsRequired = 1;
        [_imageView addGestureRecognizer:tap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        [_imageView addGestureRecognizer:doubleTap];
        [tap requireGestureRecognizerToFail:doubleTap];
        
        UILongPressGestureRecognizer *longpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:longpress];
    }
    return self;
}

- (void)removeFromSuperview{
    CGImageRelease(originImageRef);
    [self clearMemory];
    [super removeFromSuperview];
}

- (void)longPress:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state==UIGestureRecognizerStateBegan) {
    }
}

- (void)reset{
    self.zoomScale = self.minimumZoomScale;
    self.contentOffset = CGPointZero;
}

- (void)reloadRotate{
    float progress1 = self.contentOffset.y/self.contentSize.height;
    if (splitImage&&splitImage.count>0) {
        CGSize size = originSize;
        float scale = size.width/self.frame.size.width;
        splitHeight = self.frame.size.height*scale;
        int part = size.height/splitHeight;
        if ((NSInteger)size.height%(NSInteger)splitHeight!=0) {
            part+=1;
        }
        [splitImage removeAllObjects];
        for (int i=0; i<part; i++) {
            CGRect partRect = CGRectMake(0, i*splitHeight, size.width, splitHeight);
            [splitImage addObject:NSStringFromCGRect(partRect)];
        }
        [self setMaxMinZoomScalesForCurrentBounds:YES];
        [self loadScrollViewWithPage:0];
        [self loadScrollViewWithPage:1];
    } else {
        [self setMaxMinZoomScalesForCurrentBounds:YES];
    }
    if (self.contentSize.height>self.frame.size.height) {
        self.contentOffset = CGPointMake(0, self.contentSize.height*progress1);
    }
}

- (void)setMaxMinZoomScalesForCurrentBounds:(BOOL)rotate{
    self.maximumZoomScale = 1;
    self.minimumZoomScale = .1;
    self.zoomScale = 1;
    CGRect photoImageViewFrame;
    photoImageViewFrame.origin = CGPointZero;
    if (splitImage&&splitImage.count>0) {
        photoImageViewFrame.size = originSize;
    } else {
        photoImageViewFrame.size = _imageView.image.size;
    }
    _imageView.frame = photoImageViewFrame;
    self.contentSize = photoImageViewFrame.size;
    
    // Bail if no image
    if (_imageView.image == nil&&splitImage==nil&&splitImage.count<=0) return;
    
    // Reset position
    //	_imageView.frame = CGRectMake(0, 0, _imageView.frame.size.width, _imageView.frame.size.height);
    CGFloat minScale = (self.bounds.size.width-.1)/_imageView.frame.size.width;
    
    // Calculate Max
    CGFloat maxScale = 1+minScale;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 2.5;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    //	float zoomScale = [self initialZoomScaleWithMinScale];
    self.zoomScale = self.minimumZoomScale;
    
    self.contentOffset = CGPointZero;
    
    // If we're zooming to fill then centralise
    //    if (self.zoomScale != minScale) {
    //        // Centralise
    //        self.contentOffset = CGPointMake((_imageView.width * self.zoomScale - photoImageViewFrame.size.width) / 2.0,
    //                                         (_imageView.height * self.zoomScale - photoImageViewFrame.size.height) / 2.0);
    //        // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    //        self.scrollEnabled = NO;
    //    }
    // Layout
    needLayout = YES;
    [self setNeedsLayout];
}

- (void)layoutSubviews{
    if (!needLayout) {
        return;
    }
    [super layoutSubviews];
    if (!self.delegate) {
        return;
    }
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _imageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_imageView.frame, frameToCenter)){
        _imageView.frame = frameToCenter;
    }
}

- (void)loadImage:(ALAsset *)asset{
    _imageView.image = [ASSETHELPER getImageFromAsset:asset type:ASSET_PHOTO_ASPECT_THUMBNAIL];
    [self progressImage];
    NSInteger flag = self.tag;
    [[JFImageManager sharedManager] imageWithAsset:asset resultHandler:^(CGImageRef imageRef, BOOL longImage) {
        if (flag==self.tag) {
            if (longImage) {
                originSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
                splitImage = [[NSMutableArray alloc] init];
                originImageRef = imageRef;
                float scale = originSize.width/self.frame.size.width;
                splitHeight = self.frame.size.height*scale;
                splitHeight = ceilf(splitHeight);
                int part = originSize.height/splitHeight;
                if ((NSInteger)originSize.height%(NSInteger)splitHeight!=0) {
                    part+=1;
                }
                for (int i=0; i<part; i++) {
                    CGRect partRect = CGRectMake(0, i*splitHeight, originSize.width, splitHeight);
                    [splitImage addObject:NSStringFromCGRect(partRect)];
                }
                [self progressImage];
            } else {
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (flag==self.tag) {
                        _imageView.image = image;
                        [self progressImage];
                    }
                });
            }
        }
    }];
}

- (void)progressImage{
    if (splitImage&&splitImage.count>0) {
        for (UIView *temp in _imageView.subviews) {
            [temp removeFromSuperview];
        }
        [self loadScrollViewWithPage:0];
        [self loadScrollViewWithPage:1];
    } else {
        [self setMaxMinZoomScalesForCurrentBounds:NO];
    }
}

- (void)clearScrollViewWithPage:(NSInteger)page{
    if (page < 0)
        return;
    if (page >= splitImage.count)
        return;
    UIImageView *photoView = (UIImageView *)[_imageView viewWithTag:page+1];
    if (photoView) {
        photoView.image = nil;
        [photoView removeFromSuperview];
    }
}

- (UIImage *)normalizeImage:(UIImage *)image {
    int width = image.size.width;
    int height = image.size.height;
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL,
                                                         width,
                                                         height,
                                                         8, (4 * width),
                                                         genericColorSpace,
                                                         (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationDefault);
    CGRect destRect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(thumbBitmapCtxt, destRect, image.CGImage);
    CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
    CGContextRelease(thumbBitmapCtxt);
    UIImage *result = [UIImage imageWithCGImage:tmpThumbImage];
    CGImageRelease(tmpThumbImage);
    
    return result;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (!scrollView.decelerating&&!scrollView.tracking&&!scrollView.dragging) {
        return;
    }
    if (splitImage&&splitImage.count>0) {
        float scale = 1+(scrollView.zoomScale-scrollView.minimumZoomScale);
        CGFloat pageHeight = scrollView.frame.size.height*scale;
        int page = floor((scrollView.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
        if (fabs(scrollView.zoomScale-scrollView.minimumZoomScale)<=.01) {
            [self clearScrollViewWithPage:page-2];
            [self clearScrollViewWithPage:page+2];
        }
        [self loadScrollViewWithPage:page-1];
        [self loadScrollViewWithPage:page];
        [self loadScrollViewWithPage:page+1];
    }
}

- (void)loadScrollViewWithPage:(NSInteger)page
{
    if (page < 0)
        return;
    if (page >= splitImage.count)
        return;
    
    UIImageView *photoView = (UIImageView *)[_imageView viewWithTag:page+1];
    if (photoView==nil) {
        CGRect partRect = CGRectFromString(splitImage[page]);
        photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, page*splitHeight, partRect.size.width, partRect.size.height)];
        photoView.tag = page+1;
        [_imageView addSubview:photoView];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGImageRef subimageRef = CGImageCreateWithImageInRect(originImageRef, partRect);
            UIImage *image = [self normalizeImage:[UIImage imageWithCGImage:subimageRef]];
            dispatch_async(dispatch_get_main_queue(), ^{
                photoView.image = image;
                CGRect frame = photoView.frame;
                frame.size.height = image.size.height;
                photoView.frame = frame;
                if (_imageView.image) {
                    [self setMaxMinZoomScalesForCurrentBounds:NO];
                    _imageView.image = nil;
                }
            });
            CGImageRelease(subimageRef);
            subimageRef = nil;
        });
    }
}

- (void)clearMemory{
    if (splitImage&&splitImage.count>0) {
        float scale = 1+(self.zoomScale-self.minimumZoomScale);
        CGFloat pageHeight = self.frame.size.height*scale;
        int page = floor((self.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
        if (fabs(self.zoomScale-self.minimumZoomScale)<=.01) {
            for (NSInteger i=0; i<splitImage.count; i++) {
                if (i!=page&&i!=page+1&&i!=page-1) {
                    [self clearScrollViewWithPage:i];
                }
            }
        }
        [splitImage removeAllObjects];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView1 {
    return _imageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
    zooming = YES;
    scrollView.scrollEnabled = YES; // reset
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView1 withView:(UIView *)view atScale:(CGFloat)scale {
    zooming = NO;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self layoutIfNeeded];
}

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    [_photoDelegate tap];
}

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (_imageView) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = _imageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)tap {
    //    if (splitImage&&splitImage.count>0) {
    //        return;
    //    }
    CGPoint touchPoint = [tap locationInView:_imageView];
    // Zoom
    if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
    } else {
        // Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];
        
    }
}

- (void)dealloc{
    self.delegate = nil;
    _imageView.image = nil;
//    NSLog(@"dealloc photo", nil);
}

@end
