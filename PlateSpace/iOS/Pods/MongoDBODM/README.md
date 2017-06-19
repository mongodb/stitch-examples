# [![Stitch](docs/stitch_beta.png)](https://stitch.mongodb.com/)

![iOS](https://img.shields.io/badge/platform-iOS-blue.svg) [![Swift 3.0](https://img.shields.io/badge/swift-3.0-orange.svg)](https://developer.apple.com/swift/) ![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202-lightgrey.svg) [![Cocoapods compatible](https://img.shields.io/badge/pod-v0.1.0-ff69b4.svg)](#Cocoapods)

## Creating a new app with the iOS SDK

### Set up an application on Stitch
1. Go to https://stitch.mongodb.com/ and log in
2. Create a new app with your desired name
3. Take note of the app's client App ID by going to Clients under Platform in the side pane
4. Go to Authentication under Control in the side pane and enable "Allow users to log in anonymously"

### Set up a project in XCode using Stitch

#### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build Stitch iOS 0.1.0+.

To integrate the iOS SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'StitchCore', '~> 0.1.0'
    # optional: for accessing a mongodb client
    pod 'MongoDBService', '~> 0.1.0'
    # optional: for using mongodb's ExtendedJson
    pod 'ExtendedJson', '~> 0.1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

#### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate the iOS SDK into your project manually.

#### Embedded Framework

- Open up Terminal, `cd` into your top-level project directory, and run the following command "if" your project is not initialized as a git repository:

  ```bash
  $ git init
  ```

- Add the iOS SDK as a git [submodule](http://git-scm.com/docs/git-submodule) by running the following command:

  ```bash
  $ git submodule add https://github.com/10gen/stitch-ios-sdk.git
  ```

- Open the new `stitch-ios-sdk` folder, and drag the `StitchCore.xcodeproj` into the Project Navigator of your application's Xcode project.

    > It should appear nested underneath your application's blue project icon. Whether it is above or below all the other Xcode groups does not matter.

- Select the `StitchCore.xcodeproj` in the Project Navigator and verify the deployment target matches that of your application target.
- Next, select your application project in the Project Navigator (blue project icon) to navigate to the target configuration window and select the application target under the "Targets" heading in the sidebar.
- In the tab bar at the top of that window, open the "General" panel.
- Click on the `+` button under the "Embedded Binaries" section.
- You will see two different `StitchCore.xcodeproj` folders each with two different versions of the `StitchCore.framework` nested inside a `Products` folder.

    > It does not matter which `Products` folder you choose from, but it does matter whether you choose the top or bottom `StitchCore.framework`.

- Select the top `StitchCore.framework` for iOS and the bottom one for OS X.

- For adding the other modules, `MongoDBService`, `ExtendedJson`, or `StitchGCM`, follow the same process above but with the respective `.xcodeproj` files.

- And that's it!

  > The `StitchCore.framework` is automagically added as a target dependency, linked framework and embedded framework in a copy files build phase which is all you need to build on the simulator and a device.

---

### Using the SDK

TODO: Write usage instructions.

#### Set up Push Notifications (GCM)

##### Set up a GCM provider

1. Create a Firebase Project
2. Click Add Firebase to your iOS app
3. Skip downloading the config file
4. Skip adding the Firebase SDK
5. Click the gear next to overview in your Firebase project and go to Project Settings
6. Go to Cloud Messaging and take note of your Legacy server key and Sender ID
7. In Stitch go to the Notifications section and enter in your API Key (legacy server key) and Sender ID

##### Receive Push Notifications in iOS

1. TODO: Write enabling push.

2. To create a GCM Push Provider by asking Stitch, you must use the *getPushProviders* method and ensure a GCM provider exists:

```swift
self.stitchClient.getPushProviders().response { (result: StitchResult<AvailablePushProviders>) in
    if let gcm = result.value?.gcm {
        let listener = MyGCMListener(gcmClient: StitchGCMPushClient(stitchClient: self.stitchClient, info: gcm))

	StitchGCMContext.sharedInstance().application(application,
						      didFinishLaunchingWithOptions: launchOptions,
						      gcmSenderID: "<YOUR-GCM-SENDER-ID>",
						      stitchGCMDelegate: listener)
    }
}
```

3. To begin listening for notifications, set your `StitchGCMDelegate` to the StitchGCMContext:

```swift
class MyGCMDelegate: StitchGCMDelegate {
    let gcmClient: StitchGCMPushClient
        
    init(gcmClient: StitchGCMPushClient) {
        self.gcmClient = gcmClient
    }
        
    func didFailToRegister(error: Error) {
            
    }
        
    func didReceiveToken(registrationToken: String) {
            
    }
        
    func didReceiveRemoteNotification(application: UIApplication, 
				      pushMessage: PushMessage,
				      handler: ((UIBackgroundFetchResult) -> Void)? 
									  
    }
}
```

4. To register for push notifications, use the *registerToken* method on your StitchClient:

```swift
func didReceiveToken(registrationToken: String) {
    gcmClient.registerToken(token: registrationToken)
}
```
