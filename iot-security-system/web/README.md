# Web App for IoT Security System Admin Page #

* Web Application Components 
    - Authentication with Google 
    - Webcam
        + Extends react-webcam npm package 
        + On image capture, takes a picture and pases back as a Base64 encoded string (Sate set as 'Active')
    - Stitch 
        + Loads the images of users that can login – If State is 'Active'
        + Enable user to 'Remove' images – Sets state to 'Inactive'
        + On image capture, sends the image taken to the Stitch '' webhook 
    - React Components 
        + Use textbox/button to set your webcam URL 
        + Use textbox/button to set your lock URL 
