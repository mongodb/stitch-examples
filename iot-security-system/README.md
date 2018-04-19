# The Face-Recognizing IoT Security System #

The Stitch IoT Face-Recognizing Security System takes off the shelf SmartHome parts -- a camera, a deadbolt, and a generic button -- and turns them into a face-recognizing security system with a total of 200 lines of code (modulo some JSON config).

We built this project as a demonstration of how easy it is to build, using Stitch, a system that orchestrates a complex interaction of components, without having to spin up an application server. It is both a starting point for hobbyists or professionals who want to develop smart home solutions, and a tutorial for those looking to see Stitch in action.

The system is made of two major parts. The Stitch backend, which orchestrates the interaction of all the devices, is about 50 lines of code. The web-based admin UI is a single-page React application, which, at 150 lines of code, is 3x the size of the backend.

Most of the 3rd-party components were chosen because of the cleanliness of their APIs, but you could substitute anything that presents an API with minimal coding.

## Components

The system is composed of these parts:

* **MongoDB Atlas**, for storing data
* **MongoDB Stitch**, the star of the show
* A D-Link Connected Home Camera
* A Lockitron Bolt with WiFi bridge
* A Logitech Pop SmartButton with WiFi bridge
* **Face++** a face-recognition service
* A **React Web App**, running on **node.js**, which manages the authorized users and configures the IFTTT webhook URLs
* **A Google Cloud Platform App**, which we use for authentication of secutiry system administrators
* **IFTTT**, which handles all the message routing between the devices and Stitch

### Component Diagram


* Getting Started
    - Atlas
        + Create atlas...
        + get atlas 'project ID'
    - Google App
        + Get an OAuth 2.0 client ID
    - Stitch
        + fill in placeholder values
            * secrets.json
            * auth_providers/oauth2-google.json
            * services/mongodb-atlas/config.json
        + cli-import
            * import will
                - automatically re-write many id fields as it imports
                - assign app-id
                - ...
    - MongoDB
        + users collection
        + ...
    - [Face++](https://www.faceplusplus.com)
        + Have to sign up with 'Canada' as phone number
        + Click 'Send button' and fill out rest of form
        + Get a free API key
        + We're using the "Compare API"
    - Web App
        + install npm
        + install yarn
        + replace Stitch App name with yours
        + `yarn && npm start`
        + Sign in with google account
