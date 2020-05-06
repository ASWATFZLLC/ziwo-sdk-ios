# Ziwo SDK

Our team built a SDK that provides an easy way to integrate Ziwo calls to your iOS app. Written in **Swift 5**, joining **WebSockets**, **[Verto protocol](https://evoluxbr.github.io/verto-docs/)** and **[GoogleRTC](https://webrtc.org/)**, this SDK embed some of the basic features detailed below.

## Features

- [x] Verto authentication
- [x] Call agent or external number
- [x] Receive call from agent or external number
- [x] Mute microphone during a call
- [x] Set audio source to speaker during a call
- [x] Hold / Unhold a ongoing call

## Requirements
- iOS 10.0+
- Xcode 11+
- Swift 5.1+


## Installation

Use [Cocoapods](https://guides.cocoapods.org/using/getting-started.html) to add the SDK to your app.

```bash
pod 'ZiwoSDK'
```

## Initialization

For further informations about the implementation, you can check the [example app available](https://github.com/KalvadTech/ziwo-sdk-ios/tree/master/ZiwoExampleApp).

In order to setup Verto protocol, please the following steps.

1. **Set the domain**.

```swift
ZiwoSDK.shared.domain = "test-domain.aswat.co"
```

2.  Once the agent is logged on Ziwo (`.POST /auth/login`), **set the access token** returned by the request.

```swift
ZiwoSDK.shared.accessToken = accessToken
```

3. Notify Ziwo that the agent is connected and available (`.POST /agents/autoLogin`).

4. Whenever you get the agent datas (`.GET /profile`), **set the logged agent**.

```swift
ZiwoSDK.shared.setAgent(agent: agent)
```

5. Finally, **initialize the Ziwo Client**.

```swift
self.ziwoClient.initializeClient()
self.ziwoClient.delegate = self
```

Et voilà! ZiwoSDK is fully initialized and is now able to make and receive calls. (see `ZiwoClientDelegate` methods)
The SDK currently log a lot of informations about the websocket and Verto protocol communication.
If you want to deactivate the debug mode, set the `vertoDebug` boolean to `false`.

## Getting Help

- **Have a bug to report?** [Open a GitHub issue](https://github.com/KalvadTech/ziwo-sdk-ios/issues). If possible, include the version of ZiwoSDK, a full log, and a project that shows the issue.
- **Have a feature request?** [Open a GitHub issue](https://github.com/KalvadTech/ziwo-sdk-ios/issues). Tell us what the feature should do and why you want the feature.


## Contributing
Pull requests are welcome. For major changes, [please open an issue](https://github.com/KalvadTech/ziwo-sdk-ios/issues) first to discuss what you would like to change.

## License
ZiwoSDK is released under the GNU GPVL3 license. See [LICENSE](https://github.com/KalvadTech/ziwo-sdk-ios/blob/master/LICENSE) for details.
