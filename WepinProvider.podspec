#
# Be sure to run `pod lib lint WepinProvider.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WepinProvider'
  s.version          = '1.1.2'
  s.summary          = 'A short description of WepinProvider.'
  s.swift_version    = '5.0'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/WepinWallet/wepin-ios-sdk-provider-v1'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'wepin.dev' => 'wepin.dev@iotrust.kr' }
  s.source           = { :git => 'https://github.com/WepinWallet/wepin-ios-sdk-provider-v1.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'WepinProvider/Classes/**/*'

  s.module_name = 'WepinProvider'
  
  # s.resource_bundles = {
  #   'WepinProvider' => ['WepinProvider/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.dependency 'WepinCommon', '~> 1.1.2'
  s.dependency 'WepinCore', '~> 1.1.2'
  s.dependency 'WepinModal', '~> 1.1.2'
  s.dependency 'WepinLogin', '~> 1.1.2'
end
