# Todo App

## About
This app demonstrates how to build a web application that serves multiple users with shared data. It also uses OAuth 2 authentication for both Google and Facebook.

It stores data for the app in MongoDB at localhost:27017 by default.

It supports mentioning users when making comments on cards using @ followed by another user's name.

## Getting Started

1. Run the combined BaaS server (See: [BaaS - Getting Started](../../README.md))
2. Edit app_config.json and modify the clientId/clientSecret for either or both Google and Facebook auth providers.
	1. See: [Setting up Google OAuth 2 Provider](../../auth/builtin/oauth2/google/README.md)
	2. See: [Setting up Facebook OAuth 2 Provider](../../auth/builtin/oauth2/facebook/README.md)
3. Create a **creds.json** file that reflects your user from your **users.json**. 
	
	Example
	
	```
	{
   	    "user": "unique_user@domain.com",
	    "password": "password"
	}
	```
	
3. Bootstrap the app by running the import tool
	
	```
	sudo pip install ../../clients/python/
	python ../../tools/import_app.py "planner" ./creds.json ./app_config.json
	```

4. Install dependencies for the sample app, and start it:

	```
	npm install
	npm start
	```

5. In a browser, open up http://localhost:8001.

## Extras

### AWS SES Integration

The app will send emails using AWS SES when another user is mentioned using the @ functionality. The email used is sourced from Google/Facebook.

TODO(XXX): make from email to use a variable

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