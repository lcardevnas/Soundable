
Pod::Spec.new do |s|
  s.name             = 'Soundable'
  s.version          = File.read('VERSION')
  s.summary          = 'Simple sound playback for Swift applications and games'

  s.description      = <<-DESC
Soundable is a small AVFoundation-based library for playing individual sounds or queues in iOS applications. Playback, grouping, muting, looping, and completion callbacks are managed by a compact Swift API.
                       DESC

  s.homepage         = 'https://github.com/thxou/Soundable'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'thxou' => 'yo@thxou.com' }
  s.source           = { :git => 'https://github.com/thxou/Soundable.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/thxou'

  s.ios.deployment_target = '13.0'
  s.platform     = :ios, '13.0'
  s.requires_arc = true
  s.swift_version = '6.0'

  s.source_files = 'Source/*.swift'
  
end
