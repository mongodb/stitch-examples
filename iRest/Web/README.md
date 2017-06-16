# iRest Sample Web App

## Introduction
iRest is a sample web application built around a social, mobile, local restaurant search concept.  
It demonstrates using javascript sdk for data queries;
Inserting new data, paginate over existing data and sorting data using different parameters.
 
## Application flow

- Sign up and Login
- Authentication with OAuth provider (Facebook)
- Anonymous login
- Search restaurants
- View results - List view and location on map
- Filter results
- Drill down - view restaurant page (more info)
- Rate restaurant 
- Review restaurant 
 
Once logged in, the user will see a list of restaurants, sorted by their physical location in relation to the users location. The user will then be able to browse through those restaurants,in either location on map view or a list view, and use advanced filtering and keywords to search for more entries.
 
Clicking on a restaurant will leads to the restaurant's page, which displays additional details (address, website, phone) including the average rating, and reviews.
Logged in users will be able to add/edit ratings & reviews to the restaurant

## What does the Sample demonstrate?

### Init the SDK client
```javascript
const APP_NAME = '<YOUR-APP-NAME>';
const options = {};
const stitchClient = new StitchClient(APP_NAME, options);
```

### Anonymous login
Anonymous logins does not have the option to rate & add reviews to restaurants, only to view existing data.
```javascript
stitchClient.anonymousAuth();
```

### Login with Facebook
```javascript
stitchClient.authWithOAuth('facebook');
```

### Setup DB collections
```javascript
const SERVICE_NAME = '<YOUR-SERVICE-NAME>';
const DB_NAME = 'iRestDB';
const COLLECTIONS = {
  RESTAURANTS: 'restaurants',
  REVIEWS_RATINGS: 'reviewsRatings',
};

const db = stitchClient.service('mongodb', SERVICE_NAME).db(DB_NAME);
const restaurants = db.collection(COLLECTIONS.RESTAURANTS);
const reviewsRatings = db.collection(COLLECTIONS.REVIEWS_RATINGS);
```


### Getting a list of restaurants, sorted by their physical location, additional filters and keywords (regular expressions).
Using named pipeline to perform a paginatard geo-location search, passing query object to search on restaurant name and attributes.
The pagination works by increasing the `minDistance` pipe-line argument, passing it the farthest distance already recieved.
The base location are hard-coded coordinates.

```javascript

stitchClient.executePipeline([
    {
      action: 'literal',
      args: {
        items: '%%vars.geo_matches'
      },
      let: {
        geo_matches: {
          '%pipeline': {
            name: 'geoNear',
            args: {
              latitude: 40.676676,
              longitude: -73.901132,
              minDistance: new Double(minDistance),
              query: {
                name: new BSONRegExp('restaurant name', 'i'),
                'attributes.hasWifi': true,
                'attributes.openOnWeekends': true
              },
              limit: 10
            }
          }
        }
      }
    }
  ]);

```

   
### Insert data

```javascript

function getUserId() {
  return stitchClient.auth().user._id;
}

function getUserName() {
  return stitchClient.auth().user.data.name;
}

function executeUpdateRatingsPipeline(restaurantId) {
  return stitchClient.executePipeline([
    {
      action: 'literal',
      args: {
        items: [
          {
            result: '%%vars.updateRatings'
          }
        ]
      },
      let: {
        updateRatings: {
          '%pipeline': {
            name: 'updateRatings',
            args: {
              restaurantId: new ObjectID(restaurantId)
            }
          }
        }
      }
    }
  ]);
}

function addReview(rateValue, text, restaurantId) {
  const date = new Date();
  const ownerId = getUserId();
  const nameOfCommenter = getUserName();

  const query = {
    comment: text,
    restaurantId: new ObjectID(restaurantId),
    owner_id: ownerId,
    dateOfComment: date,
    rate: rateValue > 0 && rateValue,
    nameOfCommenter
  };

  return reviewsRatings.insertOne(query)
    .then(() => executeUpdateRatingsPipeline(restaurantId));
}
```


### Editing existing data in the DB 
```javascript
function updateReview(rateValue, text, reviewId, restaurantId) {
  const date = new Date();

  const query = {
    _id: new ObjectID(reviewId),
  };
 
  const update = {
    '$set': {
      comment: text,
      dateOfComment: date,
      rate: rateValue > 0 && rateValue
    }
  };

  return reviewsRatings.updateOne(query, update)
    .then(() => executeUpdateRatingsPipeline(restaurantId));
}
```

**Note:** All code snippets are extracted from `mongodb-manager.js` file.

### setup restaurants collection
- In order to add data to your restaurant collection, please download the [*Repository*](https://git.zemingo.com/MongoBaaS/MongoSmapleSoLoMo-FillRestaurantsData). and follow the instructions in the readme file.

### Setup Stitch Service
- The sample app uses Stitch as a baas, all of the backend configuration can be done via the Stitch admin console.
- After logging in to: https://stitch.mongodb.com/, set a new app, and add to it a new mongoDB service (in the left side menu by clicking “add service”)
- **Connect** - to connect the the service to a mongoDB server - after clicking on the new service button, add you own mongoDB connection string (e.g mongodb://[username:password@]host1[:port1][,host2[:port2],...[,hostN[:portN]]][/[database][?options]] ) and click save. For now on the current service is connected to a mongoDB server
- **Collections** - to add collections to your service. Simply click on the current service, then click on “rules” tab, then click on “Add namespace” to add your collection. In our example the collections are *restaurants* and *reviewsRatings*.
- **Rules** - Stitch lets you set up set of rules for every collection in your db, after creating collections in your service, just click on the collection and start defining your rules on top of the collection.
  - Restaurants: the collections rules are on the  top-level document, letting any user to read it, and not giving any write permissions (readonly)
    - Readable - {}
    - Writable - blank
  - reviewsRatings:  the rules are on the top level-document, letting any oser see all of the reviews, but the write rules let only the owner edit/add review, and not more than one entry per user, the write rules are using named pipelines which will explained widely below.
     - Readable - {}
     - Writable - 

     ```json
     {
      "$and": [
        {
          "$$root.owner_id": "$$user.id"
        },
        {
          "$or": [
            {
              "$and": [
                {
                  "$$true": {
                    "$pipeline": {
                      "name": "userHasSingleReview",
                      "args": {
                        "userId": "$$user.id",
                        "restaurantId": "$$root.restaurantId"
                      }
                    }
                  }
                },
                {
                  "$$prevRoot": {
                    "$exists": true
                  }
                }
              ]
            },
            {
              "$and": [
                {
                  "$$false": {
                    "$pipeline": {
                      "name": "userHasMoreThanOneReview",
                      "args": {
                        "userId": "$$user.id",
                        "restaurantId": "$$root.restaurantId"
                      }
                    }
                  }
                },
                {
                  "$$prevRoot": {
                    "$exists": false
                  }
                }
              ]
            }
          ]
        }
      ]
    }   
      ```
- **Authentication** - to customize the authentication behavior click on the authentication button in the menu, then enable what type of provider would you like support in your app. In our case we added Facebook authentication, anonymous authentication, and Email/Password authentication
- **Named pipelines** - Stitch lets you define named pipelines.
Named pipelines are custom pipeline requests that could be executed from the client side / by rules on top of the collections (see Rules bullet). To create named pipeline just press on pipelines button in the menu and add your own custom pipeline.
  - Paginated geoNear - in the app we are paginating from the nearest restaurant. To use this you have to implement geoNear named pipeline:

  ```json
  {
    "database": "iRestDB",
    "collection": "restaurants",
    "pipeline": [
      {
        "$geoNear": {
          "near": {
            "coordinates": [
              "$$vars.longitude",
              "$$vars.latitude"
            ],
            "type": "Point"
          },
          "query": "$$vars.query",
          "limit": "$$vars.limit",
          "minDistance": "$$vars.minDistance",
          "distanceField": "dist",
          "spherical": true
        }
      }
    ]
  }
  ```

Make sure that “skip rules” button is enabled
Add parameters for the call:  
  - Latitude : required
  - Longitude: required
  - Query : optional
  - minDistance: required
  - Limit: required
 
Make sure the “bind data to vars” is enabled and add

```json
{
  "latitude": "$$args.latitude",
  "longitude": "$$args.longitude",
  "query": "$$args.query",
  "minDistance": "$$args.minDistance",
  "limit": "$$args.limit"
}
```
 
 
Another named pipeline for example is the “userHasMoreThanOneReview“ pipeline which used by the write rule on the top of “reviewsRestaurants” collection:

```json
{
  "database": "iRestDB",
  "collection": "reviewsRatings",
  "pipeline": [
    {
      "$match": {
        "owner_id": "$$vars.userId",
        "restaurantId": "$$vars.restaurantId"
      }
    },
    {
      "$count": "result"
    },
    {
      "$match": {
        "result": {
          "$gte": 1
        }
      }
    }
  ]
}
```
 
Make sure that “skip rules” button is enabled
Add parameters for the call:
  - userName : required
  - restaurantId: required
 
 
Make sure the “bind data to vars” is enabled and add

```json
{
  "userId": "$$args.userId",
  "restaurantId": "$$args.restaurantId"
}
```

 

“updateRatings” named pipeline is counting and calculate the average rating for a single restaurant, because “Restaurant” collection is read only, we are using this pipeline which skips the collection rules and let us update the restaurant new rates: 

```json 
{
  "database": "iRestDB",
  "collection": "restaurants",
  "query": {
    "_id": "$$vars.restaurantId"
  },
  "update": {
    "$set": {
      "averageRating": "$$vars.pipelineResult.average",
      "numberOfRates": "$$vars.pipelineResult.count"
    }
  },
  "upsert": false,
  "multi": false
}
```

 
Make sure that “skip rules” button is enabled
Add parameters for the call:
  - restaurantId: required
 
 
Make sure the “bind data to vars” is enabled and add (note that aggregateRestaurant pipeline is apart of in the binded variables )

```json
{
  "restaurantId": "$$args.restaurantId",
  "pipelineResult": {
    "$pipeline": {
      "name": "aggregateRestaurant",
      "args": {
        "restaurantId": "$$args.restaurantId"
      }
    }
  }
}
```
 
 
Aggregate restaurant named pipeline: 

```json
{
  "database": "iRestDB",
  "collection": "reviewsRatings",
  "pipeline": [
    {
      "$match": {
        "restaurantId": "$$vars.restaurantId",
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
 
Make sure that “skip rules” button is enabled
Add parameters for the call:
  - restaurantId: required
 
 
Make sure the “bind data to vars” is enabled and add

```json
{
  "restaurantId": "$$args.restaurantId"
}
```



### Setup App
- Download source-code, run `npm install` or `yarn install` to install dependecies.
- Edit `src/mongodb-manager/mongodb-manager.js` file and add the IDs for your application:
  - APP_NAME - The app id can be found on Stitch Dashboard
  - SERVICE_NAME- The service name can be found on Stitch Dashboard
  - DB_NAME - The database name is the defined name in the MongoDB server
- To start the development server and to launch the app, run `yarn start` or `npm start`.
- To create a production build, run `yarn build` or `npm run build`. This will create a *build* folder with the site's static assets.

- Requirements for running the app:
  - Node v6 or above.

### Application Side
- React application developed using [*Create React App*](https://github.com/facebookincubator/create-react-app).
- Additional libraries used:
  - [date-fns](https://github.com/date-fns/date-fns)
  - [geolib](https://github.com/manuelbieh/Geolib)
  - [google-map-react](https://github.com/istarkov/google-map-react)
  - [material-ui](https://github.com/callemall/material-ui)
  - [radium](https://github.com/FormidableLabs/radium)
  - [rc-rate](https://github.com/react-component/rate)


### Database collections and schemes used in app:

- Collection `reviewsRatings`:

```json 
{
  "_id": <ObjectId>,
  "owner_id": <String>,
  "restaurantId": <ObjectId>,
  "nameOfCommenter": <String>,
  "comment": <String>,
  "rate": <Integer>,
  "dateOfComment": <Date>
}
```

	
- Collection `restaurants`:

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
 
 
 
 
 
