Pod::Spec.new do |spec|
  spec.name         = 'ZRTusKit'
  spec.version      = '0.0.1'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/itszero/ZRTusKit'
  spec.authors      = { 'Zero Cho' => 'itszero@gmail.com' }
  spec.summary      = 'Work-in-progress. Tus 1.0 protocol implementation.'
  spec.source       = { :git => 'https://github.com/itszeor/ZRTusKit.git', :tag => spec.version }
  spec.source_files = 'ZRTusKit/*.swift'

  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.10'

  spec.dependency 'BrightFutures', '~> 1.0-beta'
end
