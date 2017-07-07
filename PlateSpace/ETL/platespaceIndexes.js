db.getMongo();
db = db.getSiblingDB("platespace");
try {
  print(db.restaurants.deleteMany({ "location.coordinates": null }));
  printjson(db.restaurants.createIndex({ location: "2dsphere" }));
  printjson(db.createCollection("reviewsRatings"));
  printjson(
    db.reviewsRatings.createIndex(
      { restaurantId: 1, owner_id: 1 },
      { unique: true }
    )
  );
} catch (e) {
  print(e);
}
