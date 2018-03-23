exports = function(start, end) {
    var atlas = context.services.get('mongodb-atlas');
    var coll = atlas.db('SalesReporting').collection('Receipts');

    return coll.find(
      { "timestamp": {"$gt": start, "$lt": end } },
      { "_id": 0, "timestamp": 1, "total": 1 }
    ).sort({ "timestamp": 1 })
     .limit(100)
     .toArray();
};