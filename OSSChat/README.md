# OSSChat (Open Source SnapChat)

## Setup

1. Create an app on baas-dev.
2. Import the app:

    cli --api-key <your-api-key> app-replace ./app_config.json --appId <app ID>

3. Use the UI to change the MongoDB URL for the mdb1 service to your own atlas URL.
4. Use the UI to set the Access Key ID and Secret Access Key for your S3 account.
5. Change `BucketName` in js/stores/uploadAsset.js to be a bucket that your AWS account owns.
6. Change `APP_ID` in js/stores/BaaSService.js to be the app ID of your app.


## Development

1. Have XCode installed (from App Store)
1. Have node >= v6 installed.
1. `npm install -g react-native-cli`

## Libraries Used

- [react-native-camera](https://github.com/lwansbrough/react-native-camera)
- [react-native-swiper](https://github.com/leecade/react-native-swiper)
- [react-native-circular-progress](https://github.com/bgryszko/react-native-circular-progress)
- [react-native-video](https://github.com/react-native-community/react-native-video)
- [react-native-aws3](https://github.com/benjreinhart/react-native-aws3) (not used by referenced for help on how to upload files to s3)
- [react-native-vector-icons](https://github.com/oblador/react-native-vector-icons)
- [react-native-linear-gradient](https://github.com/react-native-community/react-native-linear-gradient)
