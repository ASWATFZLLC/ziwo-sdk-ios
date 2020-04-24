# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'
workspace 'ziwo-sdk.xcworkspace'

target 'ziwo-sdk' do
    use_frameworks!
    project './ziwo-sdk.xcodeproj'

    # Pods for ziwo-sdk
    pod 'Starscream', :git => 'https://github.com/emersonsoftware/Starscream.git', :branch => 'master'
    pod 'SwiftyJSON'
    pod 'Defaults'
    pod 'GoogleWebRTC'
    pod 'PromiseKit'
end

target 'ZiwoExampleApp' do
    use_frameworks!
    project './ziwo-sdk.xcodeproj'

    # Pods for ZiwoExampleApp
    pod 'ZiwoSDK', :path => '.'
    pod 'Alamofire'
end

target 'ziwo_sdkTests' do
    use_frameworks!
end
