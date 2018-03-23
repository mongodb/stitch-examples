exports = function() {
    var atlas = context.services.get('mongodb-atlas');
    var receipts = atlas.db('SalesReporting').collection('Receipts');
    return receipts.aggregate([
        {"$sort": {"timestamp": -1}},
        {"$sortByCount": "$toppings"},
        {"$limit": 100}
    ]).toArray();
};