# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
workspace 'ziwo-sdk.xcworkspace'

use_frameworks!

target 'ziwo-sdk' do
    project './ziwo-sdk.xcodeproj'

    # Pods for ziwo-sdk
    pod 'Starscream', :git => 'https://github.com/emersonsoftware/Starscream.git', :branch => 'master'
    pod 'SwiftyJSON'
    pod 'Defaults'
    pod 'GoogleWebRTC'
    pod 'PromiseKit'
end

target 'ZiwoExampleApp' do
    project './ziwo-sdk.xcodeproj'

    # Pods for ZiwoExampleApp
    pod 'ZiwoSDK', :path => '.'
    pod 'Alamofire'
    pod 'Permission/Microphone'
end

target 'ziwo_sdkTests' do
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
