# JFImagePicker
高性能多选图片库
[![Screenshot 1](https://raw.githubusercontent.com/johnil/JFImagePickerController/master/assets/screenshot1.png")
[![Screenshot 2](https://raw.githubusercontent.com/johnil/JFImagePickerController/master/assets/screenshot2.png")

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

##### Import
```objective-c
#import "JFImagePickerController.h"

@interface ViewController () <JFImagePickerDelegate>

@end

```

##### Load JFImagePicker
```objective-c
JFImagePickerController *picker = [[JFImagePickerController alloc] initWithPreviewIndex:temp.tag];
picker.pickerDelegate = self;
[self presentViewController:picker animated:YES completion:nil];
```

##### Delegate Method
```objective-c
- (void)imagePickerDidFinished:(JFImagePickerController *)picker{ 
	//picker.assets is all choices photo
  	[picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerDidCancel:(JFImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
```

##### Load Thumb UIImage
```objective-c
[[JFImageManager sharedManager] thumbWithAsset:asset resultHandler:^(UIImage *result) {
    //do something
}];
```

##### Load UIImage for best size
```objective-c
[[JFImageManager sharedManager] imageWithAsset:asset resultHandler:^(UIImage *result) {
    //do something
}];
```

##### clear
```objective-c
[JFImagePickerController clear];  //clear datas
```

#License

JFImagePicker is released under the MIT license. See LICENSE for details.
