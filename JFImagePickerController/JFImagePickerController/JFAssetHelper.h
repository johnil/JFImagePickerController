//
//  AssetHelper.m
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#define APP_COLOR [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]

#define ASSETHELPER    [JFAssetHelper sharedAssetHelper]

#define ASSET_PHOTO_THUMBNAIL           0
#define ASSET_PHOTO_ASPECT_THUMBNAIL    1
#define ASSET_PHOTO_SCREEN_SIZE         2
#define ASSET_PHOTO_FULL_RESOLUTION     3

@interface JFAssetHelper : NSObject

- (void)initAsset;

@property (nonatomic, strong)   ALAssetsLibrary			*assetsLibrary;
@property (nonatomic, strong)   NSMutableArray          *assetPhotos;
@property (nonatomic, strong)   NSMutableArray          *assetGroups;
@property (nonatomic)			NSInteger						currentGroupIndex;
@property (nonatomic)			NSInteger						previewIndex;
@property (readwrite)           BOOL                    bReverse;
@property (nonatomic, strong)   NSMutableArray			*selectdPhotos;
@property (nonatomic, strong)   NSMutableArray			*selectdAssets;
@property (nonatomic, strong)   NSMutableArray			*defaultAssets;
@property (nonatomic, strong)   NSString				*originStr;
@property (nonatomic, strong)	ALAsset					*selectdAsset;

+ (JFAssetHelper *)sharedAssetHelper;

// get album list from asset
- (void)getGroupList:(void (^)(NSArray *))result;
// get photos from specific album with ALAssetsGroup object
- (void)getPhotoListOfGroup:(ALAssetsGroup *)alGroup result:(void (^)(NSArray *))result;
// get photos from specific album with index of album array
- (void)getPhotoListOfGroupByIndex:(NSInteger)nGroupIndex result:(void (^)(NSArray *))result;
// get photos from camera roll
- (void)getSavedPhotoList:(void (^)(NSArray *))result error:(void (^)(NSError *))error;

- (NSInteger)getGroupCount;
- (NSInteger)getPhotoCountOfCurrentGroup;
- (NSDictionary *)getGroupInfo:(NSInteger)nIndex;

- (void)clearData;

// utils
- (UIImage *)getCroppedImage:(NSURL *)urlImage;
- (UIImage *)getImageFromAsset:(ALAsset *)asset type:(NSInteger)nType;
- (UIImage *)getImageAtIndex:(NSInteger)nIndex type:(NSInteger)nType;
- (ALAsset *)getAssetAtIndex:(NSInteger)nIndex;
- (ALAssetsGroup *)getGroupAtIndex:(NSInteger)nIndex;

@end

