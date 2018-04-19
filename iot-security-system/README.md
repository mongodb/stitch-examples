# The Face-Recognizing IoT Security System #

The Stitch IoT Face-Recognizing Security System takes off the shelf SmartHome parts -- a camera, a deadbolt, and a generic button -- and turns them into a face-recognizing security system with a total of 200 lines of code (modulo some JSON config).

We built this project as a demonstration of how easy it is to build, using Stitch, a system that orchestrates a complex interaction of components, without having to spin up an application server. It is both a starting point for hobbyists or professionals who want to develop smart home solutions, and a tutorial for those looking to see Stitch in action.

The system is made of two major parts. The Stitch backend, which orchestrates the interaction of all the devices, is about 50 lines of code. The web-based admin UI is a single-page React application, which, at 150 lines of code, is 3x the size of the backend.

Most of the 3rd-party components were chosen because of the cleanliness of their APIs, but you could substitute anything that presents an API with minimal coding.

## Components

The system is composed of these parts:

* **MongoDB Atlas**, for storing data:
    - User profiles, which contain the unique URLs that trigger their hardware
    - Authorized user images, used for facial recognition
    - Audit logs
* **MongoDB Stitch**, the star of the show
* A D-Link Connected Home Camera
* A Lockitron Bolt with WiFi bridge
* A Logitech Pop SmartButton with WiFi bridge
* **Face++** a face-recognition service
* A **React Web App**, running on **node.js**, which manages the authorized users and configures the IFTTT webhook URLs
* **A Google Cloud Platform App**, which we use for authentication of secutiry system administrators
* **IFTTT**, which handles all the message routing between the devices and Stitch

### Component Diagram


## How to set up and run this project

There are quite a few moving parts, as you can see from the above list.

### Hardware

We chose our hardware based on the availability of IFTTT services.

#### Camera
A [D-Link Connected Home Camera](http://us.dlink.com/product-category/home-solutions/connected-home/cameras/) of some kind. We used the [DCS-935L HD WiFi Camera](http://us.dlink.com/products/connect/hd-wi-fi-camera/).

#### Lock
As of the initial writing of this README, Smartlocks aren't as far along as the rest of the smarthome components, but the best one we found was the [Lockitron Bolt](https://lockitron.com). The Bolt's WiFi bridge can be a little sensitive to interference, but in most home settings it works well.

#### Button
There are plenty of options here, we're using the [Logitech POP SmartButton](https://www.logitech.com/en-us/product/pop-smart-button).

### Atlas

All the data for this project lives in a MongoDB Atlas cluster. The collections are:

* Start by Creating an [Atlas Account/Project](https://docs.atlas.mongodb.com/getting-started/#a-create-an-service-user-account)
+ Deploy a [Atlas Cluster](https://docs.atlas.mongodb.com/getting-started/#b-create-an-service-free-tier-cluster) (Use M0 for a free cluster)
+ Get your Atlas ['Project ID'](https://docs.atlas.mongodb.com/tutorial/manage-project-settings/) and [Configure API Access](https://docs.atlas.mongodb.com/configure-api-access/) so you can import the Stitch Application

### Google App
+ Get an [OAuth 2.0 client ID](https://support.google.com/cloud/answer/6158849?hl=en)

### [IFTTT](https://ifttt.com/)

+ Do we want to add anything here?

### [Face++](https://www.faceplusplus.com)

+ Sign-up (Use 'Canada' as phone number country code)
+ Click 'Send button' and fill out rest of form
+ Get a free API key
+ We will use the "Compare API"

### Stitch
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

### MongoDB
- Used to store the following information in the security-system database
    + images: Containing a set of user images and their corresponding status/information
    + settings: Contains settings for Users within the system 
- Note, access to the database and collection is set-up upon importing the application.


### Web App
- install npm
- install yarn
- replace Stitch App name with yours
- `yarn && npm start`
- Sign in with google account

