# Todo App

## About
This app demonstrates how to build a web application that serves multiple users with shared data. It also uses OAuth 2 authentication for both Google and Facebook.

It stores data for the app in MongoDB at localhost:27017 by default.

It supports mentioning users when making comments on cards using @ followed by another user's name.

## Getting Started

1. Log into BaaS and create an app with a name of your choice.
2. Create an API Key in your profile settings and keep note of the secret key.
3. Edit app_config.json and modify the clientId/clientSecret for either or both Google and Facebook auth providers.
	1. See: [Setting up Google OAuth 2 Provider](../../auth/builtin/oauth2/google/README.md)
	2. See: [Setting up Facebook OAuth 2 Provider](../../auth/builtin/oauth2/facebook/README.md)
4. Also modify the mdb1 uri to your MongoDB instance accessible from BaaS.
5. Bootstrap the app by running:

	```
	go run $GOPATH/src/github.com/10gen/baas/clients/golang/main/main.go app-replace -a <appName> app_config.json --api-key=<apiKey>
	```
6. Install dependencies for the sample app, and start it:

	```
	npm install
	APP_NAME=<appName> npm start
	```

7. In a browser, open up http://localhost:8001.

## Extras

### AWS SES Integration

The app will send emails using AWS SES when another user is mentioned using the @ functionality. The email used is sourced from Google/Facebook.

To set it up, make the following changes in the UI:

* Go to the **ses1** service.
* Change the service config to reflect your AWS access key and secret access key.

### PubNub Push Notification Integration

This app will publish messages to PubNub on a channel associated with a user when another user is mentioned using hte @ functionality. This channel is created when the user logs in for the first time.

To set it up, make the following changes in the UI:

* Go to the **pn1** service.
* Change the service config to reflect your PubNub keyset's subscribe and publish keys.

As long as you use the same keyset and create a client listening on that channel, you will receive notifications.

See the provided [Android app](./android/README.md) to play with this.

## Playground

To make changes to the app, just visit the BaaS server UI.

To start from scratch, run the following:

```
python ../../tools/import_app.py "planner" ./creds.json ./app_config.json --clean
python ../../tools/import_app.py "planner" ./creds.json ./app_config.json
```