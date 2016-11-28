# Todo App

## About
This app demonstrates how to build a web application that serves a single user with their own data. It also uses OAuth 2 authentication for both Google and Facebook.

It stores data for the app in MongoDB at localhost:27017 by default.

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
	python ../../tools/import_app.py "todo" ./creds.json ./app_config.json
	```

4. Install dependencies for the sample app, and start it:

	```
	npm install
	npm start
	```

5. In a browser, open up http://localhost:8001.

## Extras

### Twilio Trigger

This app supports Twilio triggers where a user can message a number you set up on Twilio and it will create a todo item with that message.

To set it up, make the following changes in the UI:

* Go to the **tw1** service.
* Change the service config to reflect your Twilio auth token and SID.
* In the app home, find the variable called **ourNumber** and change the **source** to your Twilio Programmable SMS number.

## Playground

To make changes to the app, just visit the BaaS server UI.

To start from scratch, run the following:

```
python ../../tools/import_app.py "todo" ./creds.json ./app_config.json --clean
python ../../tools/import_app.py "todo" ./creds.json ./app_config.json
```