# The Face-Recognizing IoT Security System #

* Intro
* Components
    - Diagram
    - List
        + Atlas
        + Stitch
        + MongoDB
        + Face++
        + React Web App
        + Google App
*  Getting Started
    - Atlas
        + Start by Creating an [Atlas Account/Project](https://docs.atlas.mongodb.com/getting-started/#a-create-an-service-user-account)
        + Deploy a [Atlas Cluster](https://docs.atlas.mongodb.com/getting-started/#b-create-an-service-free-tier-cluster) (Use M0 for a free cluster)
        + Get your Atlas ['Project ID'](https://docs.atlas.mongodb.com/tutorial/manage-project-settings/) and [Configure API Access](https://docs.atlas.mongodb.com/configure-api-access/) so you can import the Stitch Application
    - Google App
        + Get an [OAuth 2.0 client ID](https://support.google.com/cloud/answer/6158849?hl=en)
    - [IFTTT](https://ifttt.com/)
        + Do we want to add anything here?
    - [Face++](https://www.faceplusplus.com)
        + Sign-up (Use 'Canada' as phone number country code)
        + Click 'Send button' and fill out rest of form
        + Get a free API key
        + We will use the "Compare API"
    - Stitch
        + Create a [Stitch Application](https://docs.mongodb.com/stitch/getting-started/create-stitch-app/#c-add-a-stitch-app)
        + Install the [Stitch CLI](https://docs.mongodb.com/stitch/import-export/stitch-cli-reference/#install-stitch-cli) and [log-in](https://docs.mongodb.com/stitch/import-export/update-stitch-app/#procedure)
        + Fill in values necessary to link your infrastructure
            * stitch.json - [Learn More](https://docs.mongodb.com/stitch/import-export/application-schema/#application-configuration)
                - Add your app_id/name if you would like to link to the application you have created
            * secrets.json - [Learn More](https://docs.mongodb.com/stitch/import-export/application-schema/#sensitive-information)
                - Must contain your OAuth Client Secret from Google
            * auth_providers/oauth2-google.json - [Learn More](https://docs.mongodb.com/stitch/import-export/application-schema/#authentication-providers)
                - Must contain your OAuth Client ID from Google
            * services/mongodb-atlas/config.json - [Learn More](https://docs.mongodb.com/stitch/import-export/application-schema/#services)
                - You must provide the name of an existing cluster in your Atlas Project
        + Use the Stitch CLI to [update the app you've created](https://docs.mongodb.com/stitch/import-export/update-stitch-app/) or [create a new application](https://docs.mongodb.com/stitch/import-export/create-stitch-app/).  This process will:
            * Load your the application structure
            * Use your secrets.json to link services to your specific accounts
            * Automatically re-write ID fields in your files with IDs specific to your Application
            * Assign an app-id (Used to link an SDK to your application)
    - MongoDB
        + Used to store the following information in the security-system database
            * images: Containing a set of user images and their corresponding status/information
            * settings: Contains settings for Users within the system 
        + Note, access to the database and collection is set-up upon importing the application.
    - Web App
        + install npm
        + install yarn
        + replace Stitch App name with yours
        + `yarn && npm start`
        + Sign in with google account

