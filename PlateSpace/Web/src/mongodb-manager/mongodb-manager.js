import { StitchClient } from 'mongodb-stitch';
import { BSON } from 'mongodb-extjson';
import geolib from 'geolib';

const APP_NAME = '<YOUR-APP-NAME>';
const SERVICE_NAME = '<YOUR-SERVICE-NAME>';
const DB_NAME = 'PlateSpaceDB';
const COLLECTIONS = {
  RESTAURANTS: 'restaurants',
  REVIEWS_RATINGS: 'reviewsRatings'
};

const { ObjectID, BSONRegExp, Double } = BSON;
const options = {};
const stitchClient = new StitchClient(APP_NAME, options);
const db = stitchClient.service('mongodb', SERVICE_NAME).db(DB_NAME);
const restaurants = db.collection(COLLECTIONS.RESTAURANTS);
const reviewsRatings = db.collection(COLLECTIONS.REVIEWS_RATINGS);

const PAGE_SIZE = 60;
const CURRENT_LOCATION = { latitude: 40.676676, longitude: -73.901132 };

const attributeMapping = {
  WIFI: 'hasWifi',
  OPEN_ON_WEEKENDS: 'openOnWeekends',
  PARKING: 'hasParking',
  VEGETARIAN: 'veganFriendly'
};

function attributesToQuery(attributes) {
  const attributesNames = attributes
    .filter(attribute => attribute.toggled)
    .map(attribute => attributeMapping[attribute.id]);
  if (attributesNames.length === 0) return;
  const attributesQuery = {};
  attributesNames.forEach(attribute => {
    attributesQuery[`attributes.${attribute}`] = true;
  });
  return attributesQuery;
}

function restaurantsQueryExpression(
  name = '',
  attributes = [],
  restaurantsToExclude = []
) {
  const nameQuery = { name: new BSONRegExp(name, 'i') };
  const attributesQuery = attributesToQuery(attributes);
  const excludeRestaurants = {
    _id: { $nin: restaurantsToExclude.map(x => ({ $oid: x.id })) }
  };
  return Object.assign({}, nameQuery, attributesQuery, excludeRestaurants);
}

function reviewsRatingsQueryExpression(restaurantId) {
  return { restaurantId: new ObjectID(restaurantId) };
}

function getDistance(fromLocation, toLocation) {
  const distance = geolib.getDistance(fromLocation, toLocation);
  return geolib.convertUnit('mi', distance, 1);
}

function timeTo12Hours(time) {
  if (!time) return '';
  const hour = time.substring(0, 2);
  const suffix = Number(hour) >= 12 ? 'pm' : 'am';
  return (hour + 11) % 12 + 1 + suffix;
}

function timeRangeTo12Hours({ start, end }) {
  return timeTo12Hours(start) + ' - ' + timeTo12Hours(end);
}

function convertToRestaurantModel({
  _id,
  image_url,
  location,
  name,
  address,
  phone,
  openingHours,
  website,
  numberOfRates,
  averageRating,
  dist
}) {
  return {
    id: _id.toString(),
    imgSource: image_url,
    lng: location.coordinates[0],
    lat: location.coordinates[1],
    distance: getDistance(CURRENT_LOCATION, {
      longitude: location.coordinates[0].toString(),
      latitude: location.coordinates[1].toString()
    }),
    distanceRaw: dist && dist.toString(),
    name: name,
    address: address,
    phone: phone,
    openHours: timeRangeTo12Hours(openingHours),
    web: website,
    reviewsNumber: Number(numberOfRates.toString()),
    rateValue: averageRating ? averageRating.toString() : '0'
  };
}

function isValidReview({
  _id,
  owner_id,
  nameOfCommenter,
  rate,
  dateOfComment,
  comment
}) {
  if (!_id || !owner_id || !nameOfCommenter || !dateOfComment) {
    return false;
  }

  // Review must have rate or comment
  if (!rate && !comment) {
    return false;
  }
  return true;
}

function convertToReviewModel({
  _id,
  owner_id,
  nameOfCommenter,
  rate,
  dateOfComment,
  comment
}) {
  return {
    id: _id.toString(),
    authorId: owner_id,
    name: nameOfCommenter,
    rateValue: (rate && Number(rate.toString())) || undefined,
    date: dateOfComment,
    text: comment,
    editable: owner_id === getUserId()
  };
}

function firstOrUndefined(results) {
  return results && results[0];
}

function geoNear(latitude, longitude, query = {}, limit, minDistance = 0) {
  return stitchClient.executePipeline([
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
              latitude: latitude,
              longitude: longitude,
              minDistance: new Double(minDistance),
              query: query,
              limit: limit
            }
          }
        }
      }
    }
  ]);
}

function findRestaurantsByGeoNear(
  nameToSearch,
  attributes,
  minDistance = 0,
  restaurantsToExclude
) {
  const query = restaurantsQueryExpression(
    nameToSearch,
    attributes,
    restaurantsToExclude
  );
  return geoNear(
    CURRENT_LOCATION.latitude,
    CURRENT_LOCATION.longitude,
    query,
    PAGE_SIZE,
    minDistance
  )
    .then(response => response.result)
    .then(data => data.map(convertToRestaurantModel));
}

function getRestaurants() {
  return findRestaurantsByGeoNear();
}

function getFilteredRestaurants(nameToSearch, attributes) {
  return findRestaurantsByGeoNear(nameToSearch, attributes);
}

function getRestaurantDetailsById(restaurantId) {
  return restaurants
    .find({ _id: new ObjectID(restaurantId) })
    .then(data => data.map(convertToRestaurantModel))
    .then(firstOrUndefined);
}

function getRestaurantReviews(restaurantId) {
  return reviewsRatings
    .find(reviewsRatingsQueryExpression(restaurantId))
    .then(results => results.filter(isValidReview))
    .then(results => results.map(convertToReviewModel));
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

  return reviewsRatings
    .insertOne(query)
    .then(() => executeUpdateRatingsPipeline(restaurantId));
}

function updateReview(rateValue, text, reviewId, restaurantId) {
  const date = new Date();

  const query = {
    _id: new ObjectID(reviewId)
  };

  const update = {
    $set: {
      comment: text,
      dateOfComment: date,
      rate: rateValue > 0 && rateValue
    }
  };

  return reviewsRatings
    .updateOne(query, update)
    .then(() => executeUpdateRatingsPipeline(restaurantId));
}

function getUserId() {
  return stitchClient.auth().user._id;
}

function getUserName() {
  return stitchClient.auth().user.data.name;
}

function createAccount(email, password) {
  return Promise.reject();
}

function login(email, password) {
  return Promise.reject();
}

function loginWithFacebook() {
  stitchClient.authWithOAuth('facebook');
}

function loginAnonymous() {
  return stitchClient.anonymousAuth();
}

function isAnonymous() {
  return stitchClient.auth().provider === 'anon/user';
}

function isAuthenticated() {
  return !!stitchClient.authedId();
}

function logout() {
  return stitchClient.logout();
}

export const MongoDbManager = {
  getRestaurants,
  getFilteredRestaurants,
  getRestaurantDetailsById,
  getRestaurantReviews,
  createAccount,
  findRestaurantsByGeoNear,
  addReview,
  updateReview,
  login,
  loginWithFacebook,
  loginAnonymous,
  isAnonymous,
  isAuthenticated,
  logout
};
