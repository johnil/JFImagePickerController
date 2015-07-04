//
//  JFImageCollectionViewController.m
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import "JFImageCollectionViewController.h"
#import "JFImagePickerViewCell.h"
#import "JFPhotoBrowserViewController.h"
#import "JFImagePickerController.h"
#import "JFAssetHelper.h"
#import "JFImageManager.h"
#import <ImageIO/ImageIO.h>

@interface JFImageCollectionViewController () <UICollectionViewDelegate, UICollectionViewDataSource, JDPhotoBrowserDelegate>

@end

@implementation JFImageCollectionViewController {
	UICollectionView *photosList;
	NSInteger currentIndex;
    BOOL scrollToToping;
    NSTimer *timer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
	self.navigationItem.title = [[ASSETHELPER.assetGroups objectAtIndex:ASSETHELPER.currentGroupIndex] valueForProperty:ALAssetsGroupPropertyName];
	UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
	self.navigationItem.rightBarButtonItem = cancel;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNormalPhotoBrowser:) name:@"showNormalPhotoBrowser" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
	self.navigationItem.title = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cancel{
	[(JFImagePickerController *)self.navigationController cancel];
}

- (UICollectionView *)collectionView{
	return photosList;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
	UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 3;
    NSInteger size = [UIScreen mainScreen].bounds.size.width/4-1;
    if (size%2!=0) {
        size-=1;
    }
    flowLayout.itemSize = CGSizeMake(size, size);
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);

	photosList = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:flowLayout];
    photosList.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    photosList.scrollIndicatorInsets = photosList.contentInset;
	photosList.delegate = self;
	photosList.dataSource = self;
	photosList.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:photosList];
	[photosList registerClass:[JFImagePickerViewCell class] forCellWithReuseIdentifier:@"imagePickerCell"];
	[ASSETHELPER getPhotoListOfGroupByIndex:ASSETHELPER.currentGroupIndex result:^(NSArray *r) {
        [[JFImageManager sharedManager] startCahcePhotoThumbWithSize:CGSizeMake(size, size)];
		[photosList reloadData];
		if (ASSETHELPER.previewIndex>=0) {
			JFPhotoBrowserViewController *photoBrowser = [[JFPhotoBrowserViewController alloc] initWithPreview];
			photoBrowser.delegate = self.navigationController;
			[self.navigationController pushViewController:photoBrowser animated:YES];
        }

        for (NSDictionary *dict in ASSETHELPER.selectdPhotos) {
            NSArray *temp = [[[dict allKeys] firstObject] componentsSeparatedByString:@"-"];
            NSInteger row = [temp[0] integerValue];
            NSInteger group = [temp[1] integerValue];
            if (group==ASSETHELPER.currentGroupIndex) {
                [photosList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
                break;
            }
        }
	}];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
	return [ASSETHELPER getPhotoCountOfCurrentGroup];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
	JFImagePickerViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"imagePickerCell" forIndexPath:indexPath];
	cell.indexPath = indexPath;
    cell.tag = indexPath.item;
    ALAsset *asset = [ASSETHELPER getAssetAtIndex:indexPath.row];
    [[JFImageManager sharedManager] thumbWithAsset:asset resultHandler:^(UIImage *result) {
        if (cell.tag==indexPath.item) {
            cell.imageView.image = result;
        }
    }];
	BOOL hasItem = NO;
	int num = 0;
	for (NSDictionary *temp in ASSETHELPER.selectdPhotos) {
		if ([[[temp allKeys] firstObject] isEqualToString:[NSString stringWithFormat:@"%ld-%ld",(long)indexPath.row, (long)ASSETHELPER.currentGroupIndex]]) {
			num = [[[temp allValues] firstObject] intValue];
			hasItem = YES;
		}
	}
	if (hasItem) {
		[cell selectOfNum:num];
	} else {
		[cell selectOfNum:-1];
	}
	return cell;
}

- (void)showNormalPhotoBrowser:(NSNotification *)notifi{
	currentIndex = [notifi.object row];
	JFPhotoBrowserViewController *photoBrowser = [[JFPhotoBrowserViewController alloc] initWithNormal];
	photoBrowser.delegate = self;
	[self.navigationController pushViewController:photoBrowser animated:YES];
}

- (NSInteger)numOfPhotosFromPhotoBrowser:(JFPhotoBrowserViewController *)browser{
	return [ASSETHELPER getPhotoCountOfCurrentGroup];
}

- (NSInteger)currentIndexFromPhotoBrowser:(JFPhotoBrowserViewController *)browser{
	return currentIndex;
}

- (ALAsset *)assetWithIndex:(NSInteger)index fromPhotoBrowser:(JFPhotoBrowserViewController *)browser{
    return [ASSETHELPER getAssetAtIndex:index];
}

- (void)photoBrowser:(JFPhotoBrowserViewController *)browser didShowPage:(NSInteger)page{
    [photosList scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:page inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}

- (JFImagePickerViewCell *)cellForRow:(NSInteger)row{
	return (JFImagePickerViewCell *)[photosList cellForItemAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
}

@end
