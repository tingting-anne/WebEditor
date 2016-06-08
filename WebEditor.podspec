#
# Be sure to run `pod lib lint WebEditor.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WebEditor'
  s.version          = '0.1.0'
  s.summary          = 'A simple web editor.'
  s.description      = 'A simple rich text editor based on webView written in swift'
  s.homepage         = 'https://github.com/tingting-anne/WebEditor.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'liutingting' => 'liutingting_fly@163.com' }
  s.source           = { :git => 'https://github.com/tingting-anne/WebEditor.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'WebEditor/Classes/*'
  
  s.resource_bundles = {
    'WebEditor' => ['WebEditor/Assets/*.png']
  }
  s.dependency 'SnapKit'

end
