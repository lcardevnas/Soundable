#
# Be sure to run `pod lib lint Klendario.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Soundable'
  s.version          = File.read('VERSION')
  s.summary          = 'Playing sounds in your Swift applications and games never was that easy'

  s.description      = <<-DESC
Soundable is a tiny library that uses `AVFoundation` to manage the playing of sounds in iOS applications in a simple and easy way. You can play single audios, in sequence and in paralel, all is handled by the Soundable library and all they have completion closures when playing finishes.
                       DESC

  s.homepage         = 'https://github.com/thxou/Soundable'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'thxou' => 'yo@thxou.com' }
  s.source           = { :git => 'https://github.com/thxou/Soundable.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/thxou'

  s.ios.deployment_target = '9.0'
  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Source/*.swift'
  
end
