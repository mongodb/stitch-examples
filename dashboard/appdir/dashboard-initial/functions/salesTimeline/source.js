exports = function(start, end) {
  // Connect to MongoDB Atlas
  var atlas = context.services.get('mongodb-atlas');
  var receipts = atlas.db('SalesReporting').collection('Receipts');

  // Prepare the query and projection documents
  var query = { "timestamp": {"$gt": start, "$lt": end } }; // Find documents with a timestamp between the provided start and end times
  var projection = { "_id": 0,"timestamp": 1, "total": 1 }; // Return only the timestamp and total fields
  
  // Query the SalesReporting.Receipts collection
  var timeline = receipts
    .find(query, projection)
    .sort({ timestamp: 1 })
    .limit(100)
    .toArray();

  return timeline;
};