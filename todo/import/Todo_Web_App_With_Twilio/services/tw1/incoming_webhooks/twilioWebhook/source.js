exports = function(args) {
    var db = context.services.get("mongodb-atlas").db("todo");
    var user = db.collection("users").findOne({
        "phone_number": args.From
    });

    if (user) {
        db.collection("items").insertOne({
            "text": args.Body,
            "owner_id": user._id
        });
    }
} 