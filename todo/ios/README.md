# Todo iOS App

## About
This app demonstrates how to build a version of the Todo app on iOS. It enables a user to authenticate to Stitch via Facebook, Google, registering using an email and a password or login anonymously, and serves each user to their own data.

## Requirements

- iOS 9.0+
- Xcode 8.2+

## Getting Started

### Create a new app
1. Go to https://stitch.mongodb.com and log in.
2. Click on "Create a new app" and give it a name.
3. Go to "Clients" on the left side nav and take note of the App ID for your app.

### Configure your iOS app
1. Open the project in Xcode, make sure to open **.xcworkspace*.
2. Set your Stitch App ID under Stitch-Info.plist (in MongoDBSample/Resources).
3. Run the app.
 

## Authentication

### Configure your app's authentication
Go to *Authentication* on the left side nav and enable at least one of authentication providers out of:
* [Google](#Google Authentication)
* [Facebook](#Facebook Authentication)
* Email/Password
* Anonynous


### Google Authentication
1. [Follow the steps](https://developers.google.com/identity/sign-in/ios/) to create an app in the Google developer console, make sure you enable Google Sign In. Download the generated `GoogleService-Info.plist` file and drag it into the app's Resources group.
2. Open Xcode and click on the project file, click the Info tab, find the `URL Types` section and add a new item. Under `URL Schemes` enter the value of the `REVERSED_CLIENT_ID` string in GoogleService-Info.plist.
3. Open the [Google Developer Console](https://console.developers.google.com/apis/credentials), find your generated app credentials and open the **Web Client** under *OAuth 2.0 client IDs*, you should find your `Client ID` and `Client Secret`, copy the velues into the respective values in your Stitch app console, under the Google configuration in the Authentication side nav.


### Facebook Authentication
1. Open [Facebook Developers](https://developers.facebook.com/) and add a new app.
2. Open Xcode and click on the project file, click the Info tab, find the `URL Types` section and add a new item. Under `URL Schemes` enter `fb<Your_Facebook_App_ID>`.
3. Open the Info.plist file and enter your Facebook app ID under `FacebookAppID`.
4. Head to your Stitch app console and copy your Facebook app ID and secret into the respective values in your Stitch app console, under the Google configuration in the Authentication side nav.
