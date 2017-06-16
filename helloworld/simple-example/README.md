# HelloWorld sample app.

### Create a new app
1. Go to https://baas-dev.10gen.cc/ and log in.
2. Click on "Create a new app" and give it a name.
3. Go to "Clients" on the left side nav and take note of the App ID for your app.

### Set up authentication providers

Now that the app exists, you need to set up a way for new users to log in. 
Go to the **Authentication** link in the left-side panel. Anonymous login is
already supported so if this good enough, you can skip past Facebook and Google
setup. Otherwise, follow the instructions for at least one of the providers listed below:

##### Facebook

1. Create an app on Facebook (See: [Facebook - Register and Configure an App](https://developers.facebook.com/docs/apps/register))
2. On your app dashboard, click Add Product.
3. Add the Facebook Login product.
4. Go to the settings for Facebook Login.
5. Under "Valid OAuth redirect URIs" add the following entry:
	`https://baas-dev.10gen.cc/api/client/v1.0/auth/callback`

Return back to the Stitch authentication settings page, and enter your App ID and App Secret as client ID and client secret respectively from the Facebook app dashboard. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

##### Google
1. Get your client ID and client secret (See: [Google - Setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849?hl=en))
2. Click the edit button for your credentials on the Google API Manager.
3. For Authorized redirect URIs, add the following entry:
	`https://baas-dev.10gen.cc/api/client/v1.0/auth/callback` 
4. On the Stitch admin site

Return back to the Stitch authentication settings page, and enter your client ID and client Secret in the Google auth settings panel. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

### Set up the MongoDB service

1. Choose the `mongodb1` service on the left nav panel.
2. Under the "Config" tab for the `mongodb1` service, put in the URI for your MongoDB cluster found by clicking connect on your cluster in Atlas.
3. Click save.

### Find your default namespace

In the "Rules" tab of the MongoDB service, look for a rule that corresponds to a MongoDB database and collection. It should look like app-<characters>.items. Take note of this as this is the MongoDB namespace you'll use for this example.

### Serve the app

Edit `index.html` in this directory, and change the lines `var MY_APP_ID = "..."` and `var MY_DB = "..."` so that they contain the ID of the app you took note of earlier on the Clients page and the DB portion of the namespace of the rule you found.
Then run the command:

`python -m SimpleHTTPServer`

Then in the browser, go to http://localhost:8000/.


