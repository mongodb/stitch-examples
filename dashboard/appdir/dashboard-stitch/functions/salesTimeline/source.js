exports = function(start, end) {
  // Connect to MongoDB Atlas
  const atlas = context.services.get('mongodb-atlas');
  const receipts = atlas.db('SalesReporting').collection('Receipts');

  // Prepare the query and projection documents
  const query = { "timestamp": {"$gt": start, "$lt": end } }; // Find documents with a timestamp between the provided start and end times
  const projection = { "_id": 0,"timestamp": 1, "total": 1 }; // Return only the timestamp and total fields
  
  // Query the SalesReporting.Receipts collection
  const timeline = receipts
    .find(query, projection)
    .sort({ timestamp: 1 })
    .limit(100)
    .toArray();

  return timeline;
};