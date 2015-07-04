//
//  JFImageManager.m
//  JFImagePickerController
//
//  Created by Johnil on 15/7/4.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import "JFImageManager.h"
#import "JFAssetHelper.h"
#import <ImageIO/ImageIO.h>

@implementation JFImageManager {
    NSCache *memCache;
    NSMutableDictionary *resuleHandlers;
}

+ (JFImageManager *)sharedManager{
    static JFImageManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[JFImageManager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        resuleHandlers = [[NSMutableDictionary alloc] init];
        memCache = [[NSCache alloc] init];
        memCache.name = @"com.johnil.JFImagePickerController.caches";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)clearMem{
    [memCache removeAllObjects];
}

- (void)memoryWarning{
    [self clearMem];
}

- (void)startCahcePhotoThumbWithSize:(CGSize)toSize{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *assets = ASSETHELPER.assetPhotos;
        for (ALAsset *asset in assets) {
            CGImageRef fullImageRef = nil;
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            screenSize.height *= [UIScreen mainScreen].scale;
            screenSize.width *= [UIScreen mainScreen].scale;
            CGSize size;
            CGRect partRect = CGRectZero;
            CGSize dimensions = asset.defaultRepresentation.dimensions;
            float maxPixel = 0;
            if (dimensions.width>dimensions.height) {
                if (dimensions.width/2>dimensions.height&&dimensions.width/2>screenSize.width&&dimensions.height>toSize.height*[UIScreen mainScreen].scale) {
                    float scale = (dimensions.height/(toSize.width*[UIScreen mainScreen].scale));
                    if (scale<1) {
                        maxPixel = dimensions.width;
                    } else {
                        maxPixel = dimensions.width/scale;
                    }
                    fullImageRef = [self thumbnailForAsset:asset maxPixelSize:maxPixel];
                    size = CGSizeMake(CGImageGetWidth(fullImageRef), CGImageGetHeight(fullImageRef));
                    partRect = CGRectMake(size.width/2-size.height/2, 0, size.height, size.height);
                }
            } else {
                if (dimensions.height/2>dimensions.width&&dimensions.height/2>screenSize.height&&dimensions.width>toSize.width*[UIScreen mainScreen].scale) {
                    float scale = (dimensions.width/(toSize.width*[UIScreen mainScreen].scale));
                    if (scale<1) {
                        maxPixel = dimensions.height;
                    } else {
                        maxPixel = dimensions.height/scale;
                    }
                    fullImageRef = [self thumbnailForAsset:asset maxPixelSize:maxPixel];
                    size = CGSizeMake(CGImageGetWidth(fullImageRef), CGImageGetHeight(fullImageRef));
                    partRect = CGRectMake(0, size.height/2-size.width/2, size.width, size.width);
                }
            }
            UIImage *temp;
            if (fullImageRef) {
                CGImageRef part = CGImageCreateWithImageInRect(fullImageRef, partRect);
                CGImageRef tempRef = [self normalizeImage:part];
                temp =[UIImage imageWithCGImage:tempRef];
                [memCache setObject:temp forKey:asset.defaultRepresentation.filename];
                CGImageRelease(tempRef);
                CGImageRelease(part);
                tempRef = nil;
                part = nil;
                void (^resultHandler)(UIImage *result) = resuleHandlers[asset.defaultRepresentation.filename];
                if (resultHandler) {
                    [resuleHandlers removeObjectForKey:asset.defaultRepresentation.filename];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        resultHandler(temp);
                    });
                }
            } else {
                [memCache setObject:@"normal" forKey:asset.defaultRepresentation.filename];
            }
        }
    });

}

- (void)thumbWithAsset:(ALAsset *)asset
         resultHandler:(void (^)(UIImage *result))resultHandler{
    if (!resultHandler) {
        return;
    }
    UIImage *image = [UIImage imageWithCGImage:asset.thumbnail];
    resultHandler(image);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id thumb = [memCache objectForKey:asset.defaultRepresentation.filename];
        if (thumb) {
            if ([thumb isKindOfClass:[UIImage class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(thumb);
                });
            } else {
                UIImage *image = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler(image);
                });
            }
        } else {
            [resuleHandlers setValue:resultHandler forKey:asset.defaultRepresentation.filename];
        }
    });

}

- (void)imageWithAsset:(ALAsset *)asset
         resultHandler:(void (^)(CGImageRef imageRef, BOOL longImage))resultHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGSize dimensions = asset.defaultRepresentation.dimensions;
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        float maxPixel = 0;
        CGImageRef fullImageRef = nil;
        BOOL isLong = NO;
        if (dimensions.width>dimensions.height) {
            if (dimensions.width/2>dimensions.height&&dimensions.width/2>screenSize.width*[UIScreen mainScreen].scale) {
                float scale = (dimensions.height/(screenSize.width*[UIScreen mainScreen].scale));
                if (scale<1) {
                    maxPixel = dimensions.width;
                } else {
                    maxPixel = dimensions.width/scale;
                }
                fullImageRef = [self thumbnailForAsset:asset maxPixelSize:maxPixel];
                isLong = YES;
            } else {
                fullImageRef = [asset.defaultRepresentation fullScreenImage];
            }
        } else {
            if (dimensions.height/2>dimensions.width&&dimensions.height/2>screenSize.height*[UIScreen mainScreen].scale) {
                float scale = (dimensions.width/(screenSize.width*[UIScreen mainScreen].scale));
                if (scale<1) {
                    maxPixel = dimensions.height;
                } else {
                    maxPixel = dimensions.height/scale;
                }
                fullImageRef = [self thumbnailForAsset:asset maxPixelSize:maxPixel];
                isLong = YES;
            } else {
                fullImageRef = [asset.defaultRepresentation fullScreenImage];
            }
        }
        resultHandler(fullImageRef, isLong);
    });

}

- (CGImageRef)normalizeImage:(CGImageRef)imageRef{
    NSInteger width = CGImageGetWidth(imageRef);
    NSInteger height = CGImageGetHeight(imageRef);
    CGRect destRect = CGRectMake(0, 0, width, height);
    CGColorSpaceRef genericColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef thumbBitmapCtxt = CGBitmapContextCreate(NULL,
                                                         width,
                                                         height,
                                                         8, (4 * width),
                                                         genericColorSpace,
                                                         (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(genericColorSpace);
    CGContextSetInterpolationQuality(thumbBitmapCtxt, kCGInterpolationDefault);
    CGContextDrawImage(thumbBitmapCtxt, destRect, imageRef);
    CGImageRef tmpThumbImage = CGBitmapContextCreateImage(thumbBitmapCtxt);
    CGContextRelease(thumbBitmapCtxt);
    return tmpThumbImage;
}

// Helper methods for thumbnailForAsset:maxPixelSize:
static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
    ALAssetRepresentation *rep = (__bridge id)info;
    
    NSError *error = nil;
    size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:&error];
    
    if (countRead == 0 && error) {
        // We have no way of passing this info back to the caller, so we log it, at least.
        NSLog(@"thumbnailForAsset:maxPixelSize: got an error reading an asset: %@", error);
    }
    
    return countRead;
}

static void releaseAssetCallback(void *info) {
    // The info here is an ALAssetRepresentation which we CFRetain in thumbnailForAsset:maxPixelSize:.
    // This release balances that retain.
    CFRelease(info);
}

// Returns a UIImage for the given asset, with size length at most the passed size.
// The resulting UIImage will be already rotated to UIImageOrientationUp, so its CGImageRef
// can be used directly without additional rotation handling.
// This is done synchronously, so you should call this method on a background queue/thread.
- (CGImageRef)thumbnailForAsset:(ALAsset *)asset maxPixelSize:(NSUInteger)size {
    NSParameterAssert(asset != nil);
    NSParameterAssert(size > 0);
    
    ALAssetRepresentation *rep = [asset defaultRepresentation];
    
    CGDataProviderDirectCallbacks callbacks = {
        .version = 0,
        .getBytePointer = NULL,
        .releaseBytePointer = NULL,
        .getBytesAtPosition = getAssetBytesCallback,
        .releaseInfo = releaseAssetCallback,
    };
    
    CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                                                      (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(size),
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                                                      });
    CFRelease(source);
    CFRelease(provider);
    
    if (!imageRef) {
        return nil;
    }
    
    return imageRef;
}

@end
