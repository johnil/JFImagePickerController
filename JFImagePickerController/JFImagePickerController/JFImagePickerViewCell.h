//
//  JFImagePickerViewCell.h
//  JFImagePickerController
//
//  Created by Johnil on 15-7-3.
//  Copyright (c) 2015年 Johnil. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JFImagePickerViewCell : UICollectionViewCell

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *numOfSelect;
- (void)selectOfNum:(NSInteger)num;

@end
