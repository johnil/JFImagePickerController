# JFImagePicker
高性能多选图片库


###功能

多选照片

预览已选照片

针对超大图片优化

###Podfile

```ruby
platform :ios, '7.0'
pod 'JFImagePicker', :git => 'git://github.com/johnil/JFImagePickerController'
```

###How to Use

##### Step 1: Import
```objective-c
#import "JFImagePickerController.h"

@interface ViewController () <JFImagePickerDelegate>

@end

```

##### Step 2: Load JFImagePicker
```objective-c
JFImagePickerController *picker = [[JFImagePickerController alloc] initWithPreviewIndex:temp.tag];
picker.pickerDelegate = self;
[self presentViewController:picker animated:YES completion:nil];
```

##### Step 3: Delegate Method
```objective-c
- (void)imagePickerDidFinished:(JFImagePickerController *)picker{ 
	//picker.assets is all choices photo
  	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerDidCancel:(JFImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
```

##### Step 4: Load UIImage
```objective-c
[[JFImageManager sharedManager] imageWithAsset:asset resultHandler:^(UIImage *result) {
    //do something
}];
```

##### Step 5: clear
```objective-c
[JFImagePickerController clear];  //clear datas
```

#License

JFImagePicker is released under the MIT license. See LICENSE for details.
