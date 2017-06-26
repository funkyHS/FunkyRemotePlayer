
Pod::Spec.new do |s|
  s.name             = 'FunkyRemotePlayer'
  s.version          = '0.1.0'
  s.summary          = 'FunkyRemotePlayer'

  s.description      = <<-DESC
FunkyRemotePlayer可以根据url，播放远程音频资源
                       DESC

  s.homepage         = 'https://github.com/funkyHS/FunkyRemotePlayer'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'funkyHS' => 'hs1024942667@163.com' }
  s.source           = { :git => 'https://github.com/funkyHS/FunkyRemotePlayer.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'FunkyRemotePlayer/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FunkyRemotePlayer' => ['FunkyRemotePlayer/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

end
