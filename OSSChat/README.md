# OSSChat (Open Source SnapChat)

This example will show you how to create a SnapChat like app in react native using BaaS. Before you get started, you should create an API key in AWS that will let you put to a bucket of your choice (s3:PutObject and s3:PutObjectAcl). Make sure the bucket is created.

## Setup

### Create a new app
1. Go to https://baas-dev.10gen.cc/ and log in.
2. Click on "Create a new app" and give it a name.
3. Go to "Clients" on the left side nav and take note of the App ID for your app.

### Create an API Key
1. Go to your profile settings by clicking your name in the top right.
2. Create an API Key in your profile settings and keep note of the secret key.

### Download the BaaS CLI
1. Go to your profile settings by clicking your name in the top right.
2. Download the CLI that matches your platform.
3. Make sure the CLI is executable.
	1. Linux: `chmod +x ./cli`

### Configure your app_config.json
1. Modify the `mongodb1` URI to your MongoDB cluster found by clicking connect on your cluster in Atlas.
2. Modify the `s31` "accessKeyId" and "secretAccessKey" to match the credentials you want to use to access S3.
3. Modify the `buckets` value to specify the S3 bucket you want to use for this app.
4. Import the app by running

	```
	./cli app-replace --appId=<appId> app_config.json --api-key=<apiKey>
	```

5. Change `APP_ID` in js/stores/BaaSService.js to be the app ID of your app.
6. Change `BucketName` in js/stores/uploadAsset.js to be a bucket that your AWS account owns.

### Run the app
1. Install dependencies for the sample app, and start it:

	```
	npm install
	react-native run-ios
	```

## Development

1. Have XCode installed (from App Store)
2. Have node >= v6 installed.
3. `npm install -g react-native-cli`

## Libraries Used

- [react-native-camera](https://github.com/lwansbrough/react-native-camera)
- [react-native-swiper](https://github.com/leecade/react-native-swiper)
- [react-native-circular-progress](https://github.com/bgryszko/react-native-circular-progress)
- [react-native-video](https://github.com/react-native-community/react-native-video)
- [react-native-aws3](https://github.com/benjreinhart/react-native-aws3) (not used by referenced for help on how to upload files to s3)
- [react-native-vector-icons](https://github.com/oblador/react-native-vector-icons)
- [react-native-linear-gradient](https://github.com/react-native-community/react-native-linear-gradient)
