Pod::Spec.new do |s|
  s.name = 'ImagePicker'
  s.module_name = 'ImagePicker'
  s.version = '0.7.5'
  s.summary = 'An easy to use, highly configurable image picker for your chat application.'
  s.homepage = 'https://github.com/redbooth/image-picker'
  s.author = { "INLOOPX" => "info@inloopx.com" }
  s.source = { :git => 'ssh://git@github.com/redbooth/image-picker.git' } 
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '9.0'

  s.requires_arc = true

  s.source_files = 'ImagePicker/**/*.{swift,h,m}'
  s.resources = 'ImagePicker/Resources/**/*'
  s.frameworks = 'UIKit', 'Photos'
end
