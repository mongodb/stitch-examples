# HelloWord sample app.

### Create a new app
* Go to https://baas-dev.10gen.cc/ and log in.
* Click on "Create New App" and give it a name. Your name must be globally unique, so you'll probably need to pick something other than `helloworld`.

### Set up authentication providers

Now that the app exists, you need to set up a way for new users to log in. 
Go to the **Authentication** link in the left-side panel.
Follow the instructions for at least one of the providers listed below:

##### Facebook

1. Create an app on Facebook (See: [Facebook - Register and Configure an App](https://developers.facebook.com/docs/apps/register))
2. On your app dashboard, click Add Product.
3. Add the Facebook Login product.
4. Go to the settings for Facebook Login.
5. Under "Valid OAuth redirect URIs" add the following entry with your app name substituted where appropriate:
	`https://baas-dev.10gen.cc/v1/app/<your_app_name>/auth/oauth2/facebook/callback`

Return back to the BaaS authentication settings page, and enter your App ID and App Secret as client ID and client secret respectively from the Facebook app dashboard. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

##### Google
1. Get your client ID and client secret (See: [Google - Setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849?hl=en))
2. Click the edit button for your credentials on the Google API Manager.
3. For Authorized redirect URIs, add the following entry with your app name substituted where appropriate:
	`https://baas-dev.10gen.cc/v1/app/<your_app_name>/auth/oauth2/google/callback` 
4. On the BaaS admin site

Return back to the BaaS authentication settings page, and enter your client ID and client Secret in the Google auth settings panel. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

### Set up a MongoDB service

1. In the BaaS admin UI, go to "Add service..." in the left nav panel.
2. Choose "MongoDB" and name it `mdb1`, then save it.
3. Under the "Config" tab for the `mdb1` service, put in the URL for your MongoDB cluster (you need to also enable SSL if connecting to an Atlas instance) then save it.

### Create a namespace.

In the "Rules" tab of the MongoDB service, click on "Add namespace" and give it the name `my_db.items`.
Some default settings will be created for the namespace, which you can leave as-is for now.

### Serve the app

In your terminal, go to the root directory where the html file is (`examples/helloworld`).
Run the command:

`python -m SimpleHTTPServer`

Then in the browser, go to http://localhost:8000/.


