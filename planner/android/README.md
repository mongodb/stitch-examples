# Planner - Android Push Notifications

## About

This Android app serves as a base template for using PubNub and BaaS at the same time. The planner app will send messages along a channel associated with a user to PubNub which will generate push notifications in this app.

## Setup

1. Update the following application [strings.xml](./app/src/main/res/strings.xml):
	* **sub_key** - The PubNub subscription ID. Must be the same as the one used for the app.
	* **sender_id** - The id used in GCM/FCM to identify the project.
	* **channel** - The name of the channel to subscribe to. Find this in the planner home page after logging in
2. Run the application with Android Studio

## GCM/FCM

1. You can use Firebase to set up a project and enable cloud messaging. See [http://dev.tapjoy.com/faq/how-to-find-sender-id-and-api-key-for-gcm/](http://dev.tapjoy.com/faq/how-to-find-sender-id-and-api-key-for-gcm/)