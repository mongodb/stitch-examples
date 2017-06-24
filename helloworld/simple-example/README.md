# HelloWorld sample app.

### Create a new Stitch app

To use MongoDB Stitch, you must be logged in to MongoDB Atlas.

1. Go to [Atlas](www.cloud.mongodb.com?jmp=docs) and login or create an account. No credit card is required.
2. When prompted, create a group. This will be used to identify your Atlas clusters.
3. Next, deploy an M0 (FREE) Atlas cluster.
4. Wait for your cluster to initialize.
5. Click on *Stitch Apps* in the left-side panel
6. Click *Create New Application*
7. Give your application a name and link it to your M0 (FREE) Atlas Cluster. You are automatically redirected to Stitch

For detailed documentation on creating an Atlas group and cluster,
see [Getting Started with Atlas](www.docs.atlas.mongodb.com/getting-started)

### Set up authentication providers

Now that the app exists, you need to set up a way for new users to log in. 
Go to the **Authentication** link in the left-side panel. To configure anonymous
authentication, click the *Edit* button on the *Anonymous Authentication*
line to open the configuration modal. Toggle the switch to enable anonymous 
authentication.

Alternatively, configure at least one of the authentication providers listed below:

##### Facebook

1. Create an app on Facebook (See: [Facebook - Register and Configure an App](https://developers.facebook.com/docs/apps/register))
2. On your app dashboard, click Add Product.
3. Add the Facebook Login product.
4. Go to the settings for Facebook Login.
5. Under "Valid OAuth redirect URIs" add the following entry:
	`https://stitch.mongodb.com/api/client/v1.0/auth/callback`

Return back to the Stitch authentication settings page. Click
the *Edit* button on the *Facebook Authentication* line to open the configuration modal.
Enter your App ID and App Secret as client ID and client secret respectively from the Facebook app dashboard. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

##### Google
1. Get your client ID and client secret (See: [Google - Setting up OAuth 2.0](https://support.google.com/cloud/answer/6158849?hl=en))
2. Click the edit button for your credentials on the Google API Manager.
3. For Authorized redirect URIs, add the following entry:
	`https://stitch.mongodb.com/api/client/v1.0/auth/callback` 
4. On the Stitch admin site

Return back to the Stitch authentication settings page. Click the
*Edit* button on the *Google Authentication* line to open the configuration modal.
Enter your client ID and client Secret in the Google auth settings panel. Add `http://localhost:8000/` to the list of redirect URIs, and save it.

### Retrieve your Stitch Application ID

1. Click `Clients` in the left-side panel
2. Click `Copy App ID`. Save the client ID somewhere safe.

### Set up the MongoDB service

1. Click `mongodb-atlas` in the left-side panel. This represents the Atlas cluster you selected when creating the Stitch application
2. Open the `Rules` tab
3. Look for a rule that corresponds to a MongoDB database and collection. It should look like `app-<characters>.items`. Take note of this as this is the MongoDB namespace you'll use for this example.

### Serve the app

Edit `index.html` in this directory, and change the lines `var MY_APP_ID = "..."` and `var MY_DB = "..."` so that they contain the Client ID you took note of earlier on the Clients page and the DB portion of the namespace of the rule you found.
Then run the command:

`python -m SimpleHTTPServer`

Then in the browser, go to http://localhost:8000/.


