# Todo App

## About
This app demonstrates how to build a web application that serves a single user with their own data. It also uses OAuth 2 authentication for both Google and Facebook.

It stores data for the app in MongoDB at localhost:27017 by default.

## Getting Started

1. Log into BaaS and create an app with a name of your choice.
2. Create an API Key in your profile settings and keep note of the secret key.
3. Edit app_config.json and modify the clientId/clientSecret for either or both Google and Facebook auth providers.
	1. See: [Setting up Google OAuth 2 Provider](../../auth/builtin/oauth2/google/README.md)
	2. See: [Setting up Facebook OAuth 2 Provider](../../auth/builtin/oauth2/facebook/README.md)
4. Also modify the mdb1 uri to your MongoDB instance accessible from BaaS.
5. Bootstrap the app by running (your app ID is on the app's homepage):

	```
	go run $GOPATH/src/github.com/10gen/baas/clients/golang/main/main.go app-replace --appId <appId> app_config.json --api-key=<apiKey>
	```
6. Install dependencies for the sample app, and start it:

	```
	npm install
	APP_ID=<appId> npm start
	```

7. In a browser, open up http://localhost:8001.

## Extras

### Twilio Trigger

This app supports Twilio triggers where a user can message a number you set up on Twilio and it will create a todo item with that message.

To set it up, make the following changes in the UI:

* Go to the **tw1** service.
* Change the service config to reflect your Twilio auth token and SID.
* In the app home, find the variable called **ourNumber** and change the **source** to your Twilio Programmable SMS number.
