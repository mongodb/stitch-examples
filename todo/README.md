# Todo App

## About
This app demonstrates how to build a web application that serves a single user with their own data. It also uses OAuth 2 authentication for both Google and Facebook.

## Getting Started

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
1. Modify the clientId/clientSecret for either or both Google and Facebook auth providers.
	1. See: [Setting up Google OAuth 2 Provider](https://docs-mongodb-org-staging.s3.amazonaws.com/baas/draft-wip/authentication.html#google-authentication)
	2. See: [Setting up Facebook OAuth 2 Provider](https://docs-mongodb-org-staging.s3.amazonaws.com/baas/draft-wip/authentication.html#facebook-authentication)
2. Modify the `mongodb1` URI to your MongoDB cluster found by clicking connect on your cluster in Atlas.
3. Import the app by running

	```
	./cli app-replace --appId=<appId> app_config.json --api-key=<apiKey>
	```

### Run your app
1. Install dependencies for the sample app, and start it:

	```
	npm install
	APP_ID=<appId> npm start
	```

2. In a browser, open up http://localhost:8001

## Extras

### Twilio Incoming Webhook

This app supports Twilio incoming webhooks where a user can message a number you set up on Twilio and it will create a todo item with that message.

To set it up, make the following changes in the UI:

1. Go to the **tw1** service.
2. Change the service config to reflect your Twilio auth token and SID.
3. Within your tw1 service, go to the Incoming Webhooks tab and take note of "Incoming Webhook URL" by clicking on the first incoming webhook you see.
3. Go to "Values" on the side nav and find the value called **ourNumber** and change the value to your Twilio Programmable SMS number.
	1. It should have a form similar to `"+16468675309"`
4. In your Twilio console, set up a Programmable SMS service and under "Inbound Settings", check "Process Inbound Messages" and use the the webhook URL as your "Request URL".
