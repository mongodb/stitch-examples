# PlateSpace Stitch Sample Web Application

## Requirements

In order to properly run this app on your local MacBook Pro or Linux machine, you need:

* MongoDB 3.4.4 or above (required to restore the app sample dataset)
* Node.js v6 or above
* NPM v4.6.1 or above
* Firefox 47 or above, Safari 10 or above (default on MacOS Sierra), Chrome 58 or above

## Introduction

platespace is a sample web application built around a social, mobile, local restaurant search concept.
It demonstrates how to use MongoDB Stitch as a backend-as-a-service and the MongoDB Stitch JavaScript SDK to perform data queries (such as inserting new data, paginating and sorting existing data)

## Stitch Service Setup

* Sign up with a new account at `https://cloud.mongodb.com` (or sign in with an existing MongoDB Cloud account).
* You might be prompted to create a New Group Name. Enter any name, such as __Stitch Clusters__.
* Build a new cluster (such as *Stitch-Demo*) if you don't have one yet.
* If this is the first cluster in your Atlas group, scroll down to the bottom of the screen and set up the first cluster admin's username and password.
* Once your cluster has been created, navigate to the __ETL/restore__ folder and read the [README file](../ETL/restore/README.md) to restore the data set this application requires to your MongoDB Atlas cluster.
* Select __Stitch Apps__ in the left navigation menu.
* Press the __Create New Application__ button and name your application `platespace` (or any other name you wish). In the __Link to Cluster__ section, select the cluster name you just selected.
* Once your Stitch app has been created, you should be redirected to the Stitch Console at [https://stitch.mongodb.com](https://stitch.mongodb.com).

In order to get our Stitch backend-as-a-service application fully set up, we must go through the following configuration steps:

1. Set up the Stitch pipelines
1. Set up the Stitch namespace rules (The name can only contain ASCII letters, numbers, underscores, and hyphens)
1. Set up authentication (if any)
1. Set up additional services (Amazon S3 and HTTP services)

### Named pipelines

Stitch lets you define named pipelines.
Named pipelines are custom pipeline requests that could be executed from the client side / by rules on top of the collections (see Rules section below). To create a named pipeline, select the  `Pipelines` link in the left-hand menu and press the `New` button close to the `Named Pipelines` text.

#### geoNear pipeline

Paginated geoLocation pipeline * in the app we are paginating from the nearest restaurant (nearest to the CURRENT_LOCATION value in src/mongodb-manager/mongodb-manager.js).

Create a new pipeline with the following parameters:

* __Name__: `geoNear`
* __Private__: Disabled
* __Skip Rules__: Enabled
* __Can Evaluate__: Leave set to `{}`
* __Parameters__:
  * `longitude`: Required
  * `latitude`: Required
  * `query`: NOT Required (leave disabled)
  * `limit`: Required
  * `minDistance`: Required
* __Output Type__: Array
* __Service__: mongodb-atlas
* __Action__: aggregate
* __Value__:
  ```json
  {
    "database": "platespace",
    "collection": "restaurants",
    "pipeline": [
      {
        "$geoNear": {
          "near": {
            "coordinates": [
              "%%vars.longitude",
              "%%vars.latitude"
            ],
            "type": "Point"
          },
          "query": "%%vars.query",
          "limit": "%%vars.limit",
          "minDistance": "%%vars.minDistance",
          "distanceField": "dist",
          "spherical": true
        }
      }
    ]
  }
  ```
* __Bind data to %%vars__:
 ```json
 {
  "longitude": "%%args.longitude",
  "latitude": "%%args.latitude",
  "query": "%%args.query",
  "limit": "%%args.limit",
  "minDistance": "%%args.minDistance"
}
 ```
* Press the `Done` button.
* Scroll up and at the top press the `Save` button.

#### userHasSingleReview pipeline

This pipeline is used by the `Write` permission of the `platespace.reviewRatings` namespace.

Add a new named pipeline and configure the following parameters:

* __Name__: `userHasSingleReview`
* __Private__:  Disabled
* __Skip Rules__: Disabled
* __Can Evaluate__: Leave set to `{}`
* __Parameters__:
  * `userId`: Required
  * `restaurantId`: Required
* __Output Type__: Boolean
* __Service__: mongodb-atlas
* __Action__: aggregate
* __Value__:
  ```json
  {
    "database": "platespace",
    "collection": "reviewsRatings",
    "pipeline": [
      {
        "$match": {
          "owner_id": "%%vars.userId",
          "restaurantId": "%%vars.restaurantId"
        }
      },
      {
        "$count": "result"
      },
      {
        "$match": {
          "result": 1
        }
      }
    ]
  }
  ```
* __Bind data to %%vars__:

   ```json
  {
    "userId": "%%args.userId",
    "restaurantId": "%%args.restaurantId"
  }
   ```
* Press the `Done` button.
* Scroll up and at the top press the `Save` button.

#### aggregateRestaurant pipeline

Add a new pipeline named `aggregateRestaurant` and configure the following parameters:

* __Name__: `aggregateRestaurant`
* __Private__: Disabled
* __Skip Rules__: Enabled
* __Can Evaluate__: Leave set to `{}`
* __Parameters__:
  * `restaurantId`: Required
* __Output type__: Single Document
* __Service__: mongodb-atlas
* __Action__: aggregate
* __Value__:
  ```json
  {
    "database": "platespace",
    "collection": "reviewsRatings",
    "pipeline": [
      {
        "$match": {
          "restaurantId": "%%vars.restaurantId",
          "rate": {
            "$exists": true
          }
        }
      },
      {
        "$group": {
          "_id": "$restaurantId",
          "average": {
            "$avg": "$rate"
          },
          "count": {
            "$sum": 1
          }
        }
      }
    ]
  }
   ```
* __Bind data to %%vars__:
   ```json
  {
    "restaurantId": "%%args.restaurantId"
  }
   ```
* Press the `Done` button.
* Scroll up and at the top press the `Save` button.

#### updateRatings pipeline

This pipeline is called directly by the application's code when a user submits a review.

Add a new named pipeline and configure the following parameters:

* __Name__: `updateRatings`
* __Private__: Disabled
* __Skip Rules__: Enabled
* __Can Evaluate__: Leave set to `{}`
* __Parameters__:
  * `restaurantId`: Required
* __Output type__: Boolean
* __Service__: mongodb-atlas
* __Action__: update
* __Value__:
  ```json
  {
    "database": "platespace",
    "collection": "restaurants",
    "query": {
      "_id": "%%vars.restaurantId"
    },
    "update": {
      "$set": {
        "averageRating": "%%vars.pipelineResult.average",
        "numberOfRates": "%%vars.pipelineResult.count"
      }
    },
    "upsert": false,
    "multi": false
  }
  ```
* __Bind data to %%vars__:
 ```json
  {
    "restaurantId": "%%args.restaurantId",
    "pipelineResult": {
      "%pipeline": {
        "name": "aggregateRestaurant",
        "args": {
          "restaurantId": "%%args.restaurantId"
        }
      }
    }
  }
 ```
* Press the `Done` button.
* Scroll up and at the top press the `Save` button.

### Rules configuration

Stitch lets you set up rules for every collection in your database, for instance user access rules or validation rules.

* Select the __mongodb-atlas__ service, navigate to the __Rules__ tab and follow the steps below.

#### Restaurants collection rules

* Press the __New__ button and set the following parameters:
  * __Database__:  `platespace`
  * __Collection__: `restaurants`
* Press the __Create__ button.
* Select the newly created __platespace.restaurants__ collection.
* In the __Filters__ tab, delete the default filter.
* In the __Field Rules__ tab, hover over the __owner_id__ field and select the checkmark to delete it. Press __OK__ to confirm.
* In the __Field Rules__ tab, select the __Top-Level Document__ section and set the following Permissions:
  * __Read__: `{}`
  * __Write__: null (empty the field)
  * __Valid__: null
* Press the __SAVE__ button.

#### ReviewsRatings collection rules

* Press the __New__ button and set the following parameters:
  * __Database__:  `platespace`
  * __Collection__: `reviewsRatings`
* Press the __Create__ button.
* Select the newly created __platespace.reviewsRatings__ collection.
* In the __Filters__ tab, delete the default filter.
* In the __Field Rules__ tab, select the __Top-Level Document__ section and set the following Permissions::
  * __Read__: `{}`
  * __Write__:
  ```json
  {
  "%and":
    [
      {
        "%%root.owner_id": "%%user.id"
      },
      {
        "%or": [
          {
            "%and": [
              {
                "%%true": {
                  "%pipeline": {
                    "name": "userHasSingleReview",
                    "args": {
                      "userId": "%%user.id",
                      "restaurantId": "%%root.restaurantId"
                    }
                  }
                }
              },
              {
                "%%prevRoot": {
                  "%exists": true
                }
              }
            ]
          },
          {
            "%and": [
              {
                "%%false": {
                  "%pipeline": {
                    "name": "userHasSingleReview",
                    "args": {
                      "userId": "%%user.id",
                      "restaurantId": "%%root.restaurantId"
                    }
                  }
                }
              },
              {
                "%%prevRoot": {
                  "%exists": false
                }
              }
            ]
          }
        ]
      }
    ]
  }
  ```
* Leave the `owner_id` field as is.

### Authentication

The platespace app supports anonymous authentication, but only in a limited fashion. Specifically, users have to be authenticated in order to be able to submit restaurant reviews. At this point, the application suppports anonymous access, Facebook and Email/Password Authentication.

#### Email/Password authentication

1. In the Stitch Console page, navigate to __Authentication__ and press the __Edit__ button for the __Email/Password__ option.
1. In the __Email Confirmation URL__ field, enter `http://localhost:3000/#/confirm`.
1. In the __Password Reset URL__ field, enter `http://localhost:3000/#/reset` and press __Save__.
1. Navigate to the __Users__ tab and click the __Add User__ button.
1. In the __Email Address__ field, enter an email address such as `gilfoyle@piedpiper.com`.
1. In the __Password__ field, enter a password of your choice (longer than 6 characters).
1. In the __Confirm Password__ field, confirm the password you entered above.
* Repeat steps 4 to 7 above to create additional named users.

You will use these users to connect to the application.

#### Facebook authentication

##### Facebook app setup

* Navigation to the [Facebook Developers](https://developers.facebook.com/) site.
* In the right-hand corner close to your name, select __Add a New App__
* In the __Display Name__ field, enter an app name such as *PlateSpace* (that name will be displayed to your users the first time they sign in with Facebook on your app) and press the __Create App ID__ button.
* The __Select a Product__ page should be selected by default. If not, find the __Add a Product__ link in the left navigation bar and select it.
* Hover over the __Facebook Login__ product and press the __Set Up__ button.
* In the __Choose a Platform__ page, select __www__.
* In the page that opens, fill out `http://localhost:3000` in the __Site URL__ text box and press __Save__. Then press __Continue__.
* Leave this page and in the left navigation bar, select __Settings__ right under __Facebook Login__.
* Add the following entry in __Valid OAuth Redirect URIs__ text box: `https://stitch.mongodb.com/api/client/v1.0/auth/callback` and press __Save Changes__ at the bottom.
* In the left navigation bar, select __Settings__ right under __Dashboard__ and copy the __App ID__ and __App Secret__ values to a text file.

##### Stitch Facebook authentication setup

* In the Stitch Console page, navigate to __Authentication__ and press the __Edit__ button for the Facebook option.
* In the __Client ID__ field, enter your Facebook __App ID__ value.
* In the __Client Secret__ field, enter your Facebook __App Secret__ value.
* In the __Redirect URIs__ section, add `http://localhost:3000/` (don't forget the last trailing slash).
* In the __Metadata Fields__ section, select the `name` checkbox.

### Amazon Web Services and Stich S3 Setup

**Important Note**: This section requires that you have an AWS account with IAM full access permissions and S3 full access permissions.

#### Amazon Web Service configuration

The application uploads images to an S3 bucket so you will an AWS account if you want to add an image while adding or updating a restaurant review.

* Sign in (or sign up) to your AWS account at [https://aws.amazon.com](https://aws.amazon.com).
* Navigate to the IAM->Users section
* Add a user (for instance `s3.stitchuser`) with `Programmatic access` as the access type
* Press `Next:Permissions`, select `Attach existing policies directly` and select the `AmazonS3FullAccess`  policy
* Press `Next: Review` and `Create user`
* In the final screen, copy the `Access key ID` and the `Secret access key` values to a text file
* Navigate to Amazon S3 and create a bucket. Store your bucket name in the same text file as the IAM credentials above

#### Stitch S3 Service configuration

* Sign in to the MongoDB Stitch console and press the `Add Service` button in the `Services` section of the left navigation menu.
* Select the __S3__ service, name it `UploadToS3` and press the `Add service` button.
* In the __Config__ tab, select the AWS region where your bucket is located and set the __Access Key ID__ and __Secret Access Key__ text boxes to the values you stored in the text file above and press __Save__. __Important Note__: if you want to select the `us-east-1` region, make sure you select another region first and then the `us-east-1` region again.
* Select the __Rules__ tab and press the `Add Rule` button.
* Check the `put` action and in the `When` text area, enter the following JSON:
  ```json
  {
  "bucket": "%NAME_OF_YOUR_BUCKET%"
  }
  ```
* Replace `%NAME_OF_YOUR_BUCKET%` with the name of the bucket you previously created (without any percent sign).
* Press `Save`.

### Clarifai Service Setup

### Clarifai Token

The first step is to retrieve a valid Bearer token from Clarifai.

* To do so, sign up for an account at the [Clarifai Developers](https://developer.clarifai.com/signup) website.
* After you sign in on Clarifai's developer portal, click on your name at the top.
* In __Applications__, select *My First Application* and update its name.
* Scroll down and in the __Access Tokens__ section, press the __Generate Access Token__ button.
* Copy the access token and press __Save Changes__.

#### Stitch HTTP Service Setup

* Sign in to the MongoDB Stitch console and press the `Add Service` button in the `Services` section of the left nav menu.
* Select the __HTTP__ service, name it `Clarifai` and press the `Add service` button.
* Select the __Rules__ tab and press the `Add Rule` button.
* Check the `post` checkbox in the __Actions__ list
* In the __When__ text area, enter the following value:
  ```json
    {
    "%%args.url.host": {
      "%in": [
        "api.clarifai.com"
      ]
    }
  }
  ```

#### processImage Stitch Pipeline Setup

The application needs a pipeline to be able to call the Clarifai HTTP service with the proper format and parameters.

Select the __Pipelines__ link in the left-hand menu add press the `New` button. Then enter the following values:

* __Name__: `processImage`
* __Private__: Disabled
* __Skip Rules__: Enabled
* __Can Evaluate__: Leave set to `{}`
* __Parameters__:
  * imagePublicUrl: Required
* __Output type__: `Single Document`
* __Service__: {the Clarifai service}
* __Action__: `post`
* __Value__:
  ```json
  {
    "url": "https://api.clarifai.com/v2/models/aaa03c23b3724a16a56b629203edc62c/outputs",
    "headers": {
      "Authorization": [
        "Bearer [YOUR_CLARIFAI_BEARER_TOKEN]"
      ]
    },
    "body": {
      "inputs": [
        {
          "data": {
            "image": {
              "url": "%%vars.imageUrl"
            }
          }
        }
      ]
    }
  }
  ```
  __Important note__: You should update the `YOUR_CLARIFAI_BEARER_TOKEN` placeholder above with your own Clarifai Access Token.
* __Bind data to %%vars__:
 ```json
  {
    "imageUrl": "%%args.imagePublicUrl"
  }
 ```
* Press the `Done` button.
* Scroll up and at the top press the `Save` button.

## Application Setup

* Clone this repository and open a Terminal console on the `Web` folder
* Run `npm install` or `yarn install` to install dependencies.
* Edit the `src/config.js` file and customize the following paramaters depending on your MongoDB Stitch configuration:
  * __STITCH_APP_ID__: The app id can be found on Stitch Dashboard, in the `Clients` page of the left menu.
  * __MONGODB_SERVICE_NAME__: The MongoDB service name can be found on Stitch Dashboard. The default value is `mongodb-atlas` and shouldn't have to be updated
  * __DB_NAME__: The database name as defined in the MongoDB Atlas cluster. Should be left to `platespace`.
  * __CURRENT_LOCATION__: The longitude/latitude coordinates used as the (hardcoded) user location. Currently set to Hyatt Regency hotel in Chicago.
  * __S3_SERVICE_NAME__: Name of the AWS S3 service name as set in the Stitch console. Should be left to the default value of `UploadToS3`.
  * (Optional) __S3_BUCKET__: The name of the AWS S3 bucket you configured above in the *Stitch S3 Service Rules* section. Update to your own bucket name if you're using your own AWS S3 service.

## Test the application

* To start the development server and to launch the app, run `yarn start` or `npm start`.
* The default browser should open a page at [http://localhost:3000](http://localhost:3000).
* Sign in using one the named users you previously created in the __Email/Password Authentication__ section above.
* You are redirected to the list of restaurants (generated thanks to the *geoNear* pipeline).
* Select a restaurant and in the *Reviews* section, press the __Add__ button to enter a new review.
* Enter the comment of your choice, choose a rating and select an image from the __Web/src/resources__ folder.

## Application Architecture

### Database collections and schemas used in app

* `reviewsRatings` collection:

  ```json
  {
    "_id": <ObjectId>,
    "owner_id": <String>,
    "restaurantId": <ObjectId>,
    "nameOfCommenter": <String>,
    "comment": <String>,
    "rate": <Integer>,
    "dateOfComment": <Date>,
    "imageUrl": <String>,
    "imageRecognitionData": <String>

  }
  ```

* `restaurants` collection:

```json
  {
    "_id": <ObjectId>,
    "name": <String>,
    "address": <String>,
    "phone": <String>,
    "Image_url": <String>,
    "website": <String>,
    "averageRating": <Double>,
    "numberOfRates": <Double>,
    "openingHours": {
      "end": <String>,
      "start": <String>
    },
    "attributes": {
      "veganFriendly": <Boolean>,
      "openOnWeekends": <Boolean>,
      "hasParking": <Boolean>,
      "hasWifi": <Boolean>
    },
    "location": {
      "coordinates": [
        <Double>, // "longitude"
        <Double> // "latitude"
      ],
      "type": "Point"
    }
  }
  ```