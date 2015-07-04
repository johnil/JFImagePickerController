Pod::Spec.new do |s|
  s.name     = 'JFImagePicker'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'A fast ImagePicker for iOS.'
  s.homepage = 'https://github.com/johnil/JFImagePickerController'
  s.social_media_url = 'http://weibo.com/u/3732851864'
  s.authors  = { 'Johnil' => 'johnil@me.com' }
  s.source   = { :git => 'https://github.com/johnil/JFImagePickerController.git', :tag => s.version, :submodules => true }
  s.requires_arc = true

  s.ios.deployment_target = '7.0'

  s.source_files = 'JFImagePickerController/JFImagePickerController/*'

  s.frameworks = 'Foundation', 'CoreGraphics', 'UIKit', 'ImageIO', 'AssetsLibrary'

end
