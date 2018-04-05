exports = function() {
  // Connect to MongoDB Atlas
  var atlas = context.services.get('mongodb-atlas');
  var receipts = atlas.db('SalesReporting').collection('Receipts');
  
  // Prepare the aggregation pipeline stages
  var pipeline = [
    {"$sort": {"timestamp": -1}}, // Order documents descending from the most recent timestamp
    {"$limit": 100},              // Grab the 100 most recent order documents
    {"$sortByCount": "$topping"}  // Group results by topping and order the result by count
  ];
  
  // Run the aggregation to get the counts of popular toppings
  var popularToppingCounts = receipts.aggregate(pipeline).toArray();
  
  return popularToppingCounts;
};