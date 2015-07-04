//
//  JFPhotoBrowserViewController.m
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import "JFPhotoBrowserViewController.h"
#import "JFPhotoView.h"
#import "JFImagePickerController.h"
#import "JFAssetHelper.h"

@interface JFPhotoBrowserViewController () <UIScrollViewDelegate, JFPhotoDelegate>

@end

@implementation JFPhotoBrowserViewController{
	UIScrollView *photosView;
	NSInteger photoCount;
	UIButton *placeholder;
	NSMutableArray *disabledIndexs;
	NSMutableArray *backupData;
	BOOL isPreview;
	BOOL isBrowser;
	UIImageView *shotBg;
	UIView *blackView;
	NSInteger currentPage;
	BOOL shouldRoate;
}

- (JFPhotoBrowserViewController *)initWithPreview{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		isPreview = YES;
		self.automaticallyAdjustsScrollViewInsets = NO;
		self.extendedLayoutIncludesOpaqueBars = YES;
		photosView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width+10, [UIScreen mainScreen].bounds.size.height)];
		photosView.showsVerticalScrollIndicator = NO;
		photosView.showsHorizontalScrollIndicator = NO;
		photosView.pagingEnabled = YES;
		photosView.delegate = self;
		[self.view addSubview:photosView];
		self.view.backgroundColor = [UIColor blackColor];
	}
	return self;
}

- (JFPhotoBrowserViewController *)initWithNormal{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
		isPreview = NO;
		self.automaticallyAdjustsScrollViewInsets = NO;
		self.extendedLayoutIncludesOpaqueBars = YES;
		photosView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width+10, [UIScreen mainScreen].bounds.size.height)];
		photosView.showsVerticalScrollIndicator = NO;
		photosView.showsHorizontalScrollIndicator = NO;
		photosView.pagingEnabled = YES;
		photosView.delegate = self;
		[self.view addSubview:photosView];
		self.view.backgroundColor = [UIColor blackColor];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [(JFImagePickerController *)self.navigationController setLeftTitle:@"取消"];
    placeholder = [UIButton buttonWithType:UIButtonTypeCustom];
    placeholder.frame = CGRectMake(0, 0, 26, 26);
    placeholder.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1];
    placeholder.layer.cornerRadius = 13;
    placeholder.layer.borderColor = [UIColor whiteColor].CGColor;
    placeholder.layer.borderWidth = 1;
    placeholder.titleLabel.font = [UIFont systemFontOfSize:15];
    [placeholder addTarget:self action:@selector(selectPhoto) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:placeholder];
    self.navigationItem.rightBarButtonItem = item;
    CGFloat pageWidth = photosView.frame.size.width;
    NSInteger page = floor((photosView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;

    BOOL hasItem = NO;
    NSInteger num = 0;
    for (NSDictionary *temp in ASSETHELPER.selectdPhotos) {
        if ([[[temp allKeys] firstObject] isEqualToString:[NSString stringWithFormat:@"%ld-%ld",(long)page, (long)ASSETHELPER.currentGroupIndex]]) {
            num = [[[temp allValues] firstObject] intValue];
            hasItem = YES;
        }
    }
    if (hasItem||isPreview) {
        if (isPreview) {
            num = page+1;
        }
        placeholder.backgroundColor = [APP_COLOR colorWithAlphaComponent:.9];
        [placeholder setTitle:@(num).stringValue forState:UIControlStateNormal];
    }
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    ASSETHELPER.previewIndex = -1;
}

- (void)viewWillDisappear:(BOOL)animated{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
	if (!isBrowser) {
		if (ASSETHELPER.selectdPhotos.count>0) {
			[(JFImagePickerController *)self.navigationController setLeftTitle:@"预览"];
		} else {
			[(JFImagePickerController *)self.navigationController setLeftTitle:@""];
		}
		if (isPreview) {
			NSMutableArray *needDelete = [NSMutableArray array];
			for (NSNumber *num in disabledIndexs) {
				NSDictionary *temp = [ASSETHELPER.selectdPhotos objectAtIndex:num.intValue];
				NSString *str = [[temp allKeys] firstObject];
				NSArray *arr = [str componentsSeparatedByString:@"-"];
				int row = [arr[0] intValue];
				int group = [arr[1] intValue];
				if (group==ASSETHELPER.currentGroupIndex) {
					[[_delegate cellForRow:row] selectOfNum:-1];
				}
				for (NSDictionary *dict in [ASSETHELPER.selectdPhotos copy]) {
					if ([[[dict allValues] firstObject] intValue]>[[[temp allValues] firstObject] intValue]) {
						NSInteger index = [ASSETHELPER.selectdPhotos indexOfObject:dict];
						[ASSETHELPER.selectdPhotos removeObject:dict];
						[ASSETHELPER.selectdPhotos insertObject:@{[[dict allKeys] firstObject]: @([[[dict allValues] firstObject] intValue]-1)} atIndex:index];
					}
				}
				[needDelete addObject:num];
			}
			for (NSNumber *num in needDelete) {
				[ASSETHELPER.selectdPhotos removeObjectAtIndex:num.intValue];
				[ASSETHELPER.selectdAssets removeObjectAtIndex:num.intValue];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadNum" object:nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"selectdPhotos" object:nil];
		}
	}
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	disabledIndexs = [[NSMutableArray alloc] init];
	backupData = [[NSMutableArray alloc] init];
}

- (void)clearMemory{
    CGFloat pageWidth = photosView.frame.size.width;
    int page = floor((photosView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	for (UIView *temp in photosView.subviews) {
		if (temp.tag!=page+1) {
			[temp removeFromSuperview];
		}
	}
}

- (void)selectPhoto{
    CGFloat pageWidth = photosView.frame.size.width;
    NSInteger page = floor((photosView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	if (!isPreview) {
		if ([placeholder.backgroundColor isEqual:[[UIColor blackColor] colorWithAlphaComponent:.1]]) {
			if (ASSETHELPER.selectdPhotos.count>=9) {
				return;
			}
			[ASSETHELPER.selectdPhotos addObject:@{[NSString stringWithFormat:@"%ld-%ld",(long)page, (long)ASSETHELPER.currentGroupIndex]: @(ASSETHELPER.selectdPhotos.count+1)}];

			[ASSETHELPER.selectdAssets addObject:[ASSETHELPER getAssetAtIndex:page]];

			placeholder.transform = CGAffineTransformMakeScale(.5, .5);
			[UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				placeholder.transform = CGAffineTransformIdentity;
			} completion:nil];
			placeholder.backgroundColor = [APP_COLOR colorWithAlphaComponent:.9];
			[placeholder setTitle:@(ASSETHELPER.selectdPhotos.count).stringValue forState:UIControlStateNormal];
			[[_delegate cellForRow:page] selectOfNum:ASSETHELPER.selectdPhotos.count];
		} else {
			NSInteger index = 0;
			NSInteger num = 0;
			for (NSDictionary *dict in ASSETHELPER.selectdPhotos) {
				if ([[[dict allKeys] firstObject] isEqualToString:[NSString stringWithFormat:@"%ld-%ld",(long)page, (long)ASSETHELPER.currentGroupIndex]]) {
					index = [ASSETHELPER.selectdPhotos indexOfObject:dict];
					num = [[[dict allValues] firstObject] intValue];
				}
			}
			for (NSDictionary *dict in [ASSETHELPER.selectdPhotos copy]) {
				if ([[[dict allValues] firstObject] intValue]>num) {
					NSInteger index = [ASSETHELPER.selectdPhotos indexOfObject:dict];
					[ASSETHELPER.selectdPhotos removeObject:dict];
					[ASSETHELPER.selectdPhotos insertObject:@{[[dict allKeys] firstObject]: @([[[dict allValues] firstObject] intValue]-1)} atIndex:index];
				}
			}

			placeholder.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1];
			[placeholder setTitle:@"" forState:UIControlStateNormal];
			[ASSETHELPER.selectdAssets removeObjectAtIndex:index];
			[ASSETHELPER.selectdPhotos removeObjectAtIndex:index];
			[[_delegate cellForRow:page] selectOfNum:-1];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"reloadNum" object:nil];
		}
	} else {
		if ([placeholder.backgroundColor isEqual:[[UIColor blackColor] colorWithAlphaComponent:.1]]) {
			placeholder.transform = CGAffineTransformMakeScale(.5, .5);
			[UIView animateWithDuration:.3 delay:0 usingSpringWithDamping:.5 initialSpringVelocity:.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
				placeholder.transform = CGAffineTransformIdentity;
			} completion:nil];
			[disabledIndexs removeObject:@(page)];
			placeholder.backgroundColor = [APP_COLOR colorWithAlphaComponent:.9];
			[placeholder setTitle:@(page+1).stringValue forState:UIControlStateNormal];
		} else {
			[disabledIndexs addObject:@(page)];
			placeholder.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1];
			[placeholder setTitle:@"" forState:UIControlStateNormal];
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"selectdPhotos" object:nil];
}

- (void)setDelegate:(id)delegate{
	_delegate = delegate;
	photoCount = [_delegate numOfPhotosFromPhotoBrowser:self];
	photosView.contentSize = CGSizeMake(photosView.frame.size.width*photoCount, 0);
	photosView.contentOffset = CGPointMake(photosView.frame.size.width*[_delegate currentIndexFromPhotoBrowser:self], 0);
    CGFloat pageWidth = photosView.frame.size.width;
    int page = floor((photosView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	currentPage = page;
	[self loadScrollViewWithPage:page-1];
	[self loadScrollViewWithPage:page];
	[self loadScrollViewWithPage:page+1];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollview{
	if (!scrollview.tracking&&!scrollview.decelerating) {
		return;
	}
    CGFloat pageWidth = scrollview.frame.size.width;
    NSInteger page = floor((scrollview.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	currentPage = page;
	[self clearScrollViewWithPage:page-2];
	[self clearScrollViewWithPage:page+2];
	[self loadScrollViewWithPage:page-1];
	[self loadScrollViewWithPage:page];
	[self loadScrollViewWithPage:page+1];

	if (!isBrowser) {
		BOOL hasItem = NO;
		NSInteger num = 0;
		for (NSDictionary *temp in ASSETHELPER.selectdPhotos) {
			if ([[[temp allKeys] firstObject] isEqualToString:[NSString stringWithFormat:@"%ld-%ld",(long)page, (long)ASSETHELPER.currentGroupIndex]]) {
				num = [[[temp allValues] firstObject] intValue];
				hasItem = YES;
			}
		}
		if ([disabledIndexs indexOfObject:@(page)]==NSNotFound&&(hasItem||isPreview)) {
			if (isPreview) {
				num = page+1;
			}
			placeholder.backgroundColor = [APP_COLOR colorWithAlphaComponent:.9];
			[placeholder setTitle:@(num).stringValue forState:UIControlStateNormal];
		} else {
			placeholder.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.1];
			[placeholder setTitle:@"" forState:UIControlStateNormal];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    if ([_delegate respondsToSelector:@selector(photoBrowser:didShowPage:)]) {
        [_delegate photoBrowser:self didShowPage:page];
    }
    JFPhotoView *photoView = (JFPhotoView *)[photosView viewWithTag:page+2];
	if (photoView!=nil) {
		[photoView reset];
	}
    JFPhotoView *photoView1 = (JFPhotoView *)[photosView viewWithTag:page];
	if (photoView1!=nil) {
        [photoView reset];
	}
}

- (void)clearScrollViewWithPage:(NSInteger)page{
    if (page < 0)
        return;
    if (page >= photoCount)
        return;
    JFPhotoView *photoView = (JFPhotoView *)[photosView viewWithTag:page+1];
	if (photoView) {
		[photoView removeFromSuperview];
	}
}

- (void)loadScrollViewWithPage:(NSInteger)page
{
    if (page < 0)
        return;
    if (page >= photoCount)
        return;

    JFPhotoView *photoView = (JFPhotoView *)[photosView viewWithTag:page+1];
	if (photoView==nil) {
		photoView = [[JFPhotoView alloc] initWithFrame:CGRectMake(photosView.frame.size.width*page, 0, photosView.frame.size.width-10, photosView.frame.size.height)];
		photoView.tag = page+1;
		photoView.photoDelegate = self;
		[photosView addSubview:photoView];
		[photoView loadImage:[_delegate assetWithIndex:page fromPhotoBrowser:self]];
	} else if (photoView.hidden) {
		photoView.hidden = NO;
	}
}

- (void)tap{
    if (self.navigationController.navigationBarHidden) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [UIView animateWithDuration:.3 animations:^{
            CGRect frame = [(JFImagePickerController *)self.navigationController customToolbar].frame;
            frame.origin.y = [UIScreen mainScreen].bounds.size.height-44;
            [(JFImagePickerController *)self.navigationController customToolbar].frame = frame;
        }];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [UIView animateWithDuration:.3 animations:^{
            CGRect frame = [(JFImagePickerController *)self.navigationController customToolbar].frame;
            frame.origin.y = [UIScreen mainScreen].bounds.size.height;
            [(JFImagePickerController *)self.navigationController customToolbar].frame = frame;
        }];
    }
}

@end
