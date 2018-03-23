const appId = "docsuserdashboard-jwazj";

const stitch = require("mongodb-stitch"); // Set-up the MongoDB connection
const chance = require("chance").Chance(); // Package for random variables

// Seeds for the random data
const LOCATIONS = ["Store 1", "Store 2", "Store 3"];
const TOPPINGS = [
  "Pepperoni",
  "Mushrooms",
  "Onions",
  "Sausage",
  "Bacon",
  "Extra cheese",
  "Black olives",
  "Green peppers",
  "Pineapple",
  "Spinach"
];
const SIZES = ["Personal", "Small", "Medium", "Large", "X-tra Large"];

// Set-up DB Connection
const clientPromise = stitch.StitchClientFactory.create(appId);
clientPromise.then(client => {
  const db = client.service("mongodb", "mongodb-atlas").db("SalesReporting");
  const salesData = db.collection("Receipts");

  // Authenticate anonymously and then begin to load data
  client.login().then(() => generateReceipts(salesData));

  // Alternatively Use the API Key to load data more securely
  // client.authenticate("apiKey", "<YOUR API KEY>").then(() => generateReceipts(salesData));
});


// Send sample data while within this recursive loop
function generateReceipts(salesData) {
  // Create a random transaction
  const receipt = {
    timestamp: Date.now(),
    customerName: chance.name({ nationality: "en" }),
    cardNumber: chance.cc(),
    location: chance.weighted(LOCATIONS, [2, 5, 3]),
    size: chance.weighted(SIZES, [1, 2, 3, 4, 5]),
    toppings: chance.weighted(TOPPINGS, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
    total: parseFloat(chance.normal({ mean: 20, dev: 3 }).toFixed(2))
  };

  // Print to the console
  console.log(receipt);

  // Insert into MongoDB
  salesData
    .insertOne(receipt)
    .then(() => randomDelay(() => generateReceipts(salesData))) // Wait then generate a new receipt
    .catch(err =>
      console.error("\nERROR", err.json.errorCode, " ", err.json.error)
    );
}

function randomDelay(fn) {
  // Wait for a random amount of time
  setTimeout(fn, chance.integer({ min: 0, max: 3000 }));
}
