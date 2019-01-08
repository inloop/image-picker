Pod::Spec.new do |s|
  s.name = 'RedboothImagePicker'
  s.module_name = 'ImagePicker'
  s.version = '0.7.5'
  s.summary = 'An easy to use, highly configurable image picker for your chat application.'
  s.homepage = 'https://github.com/redbooth/image-picker'
  s.author = { "INLOOPX" => "info@inloopx.com" }
  s.source = { :git => 'https://github.com/redbooth/image-picker.git' }

  s.swift_version = '4.2'

  s.ios.deployment_target = '10.3'

  s.requires_arc = true

  s.source_files = 'ImagePicker/**/*.{swift,h,m}'
  s.resources = 'ImagePicker/Resources/**/*'
  s.frameworks = 'UIKit', 'Photos'

  s.license = { :type => 'MIT' }
end
