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
