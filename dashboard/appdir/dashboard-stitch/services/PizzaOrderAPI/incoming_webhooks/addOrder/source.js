exports = function(payload, response) {
  // Connect to MongoDB Atlas
  var atlas = context.services.get('mongodb-atlas');
  var receipts = atlas.db("SalesReporting").collection("Receipts");
  
  // Parse the stringified JSON body into an EJSON object
  var orderString = payload.body.text();
  var order = EJSON.parse(orderString);
  
  // The insertOne method will only succeed if the collection write rule evaluates to true
  receipts.insertOne(order).then(a => {
    // If all went according to plan, return a response object
    response.setStatusCode(201);   // 201 - Resource Created
    response.setBody(orderString); // Response body is the order document that was just inserted
  });
  
};