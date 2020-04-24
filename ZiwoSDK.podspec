Pod::Spec.new do |s|
  s.name          = "ZiwoSDK"
  s.version       = "0.0.1"
  s.summary       = "iOS SDK for Ziwo calls integration."
  s.description   = "This helps to integrate Ziwo calls using Starscream (websocket), GoogleWebRTC and Verto protocols. This SDK also embed an example app."
  s.homepage      = "https://github.com/KalvadTech/ziwo-sdk-ios"
  s.license       = "MIT"
  s.author        = "Emilien Roussel"
  s.platform      = :ios, "13.0"
  s.swift_version = "5.0"
  s.source        = {
    :git => "https://github.com/KalvadTech/ziwo-sdk-ios.git",
    :tag => "#{s.version}"
  }
  s.source_files        = "ziwo-sdk/**/*.{h,m,swift}"
  s.public_header_files = "ziwo-sdk/**/*.h"
  s.dependency 'Starscream'
  s.dependency 'SwiftyJSON'
  s.dependency 'Defaults'
  s.dependency 'GoogleWebRTC'
  s.dependency 'PromiseKit'
end
