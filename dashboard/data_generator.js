const appId = "<YOUR APP ID>";
const dashboardApiKey = "<YOUR API KEY>";

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

// Instantiate variables
let stitchClient;
let salesData;

// Create and authenticate a new StitchClient
stitch.StitchClientFactory.create(appId)
  .then(client => {
    stitchClient = client;
    return stitchClient.login(); // Log in anonymously

    // API Key authentication
    // return stitchClient.authenticate("apiKey", dashboardApiKey)
  })
  // Connect to a MongoDB Atlas collection and begin generating customer orders
  .then(() => {
    salesData = stitchClient
      .service("mongodb", "mongodb-atlas")
      .db("SalesReporting")
      .collection("Receipts");
    generateReceipts();
  });

function generateReceipts() {
  // Create a random pizza order
  const receipt = {
    timestamp: Date.now(),
    customerName: chance.name({ nationality: "en" }),
    cardNumber: chance.cc(),
    location: chance.weighted(LOCATIONS, [2, 5, 3]),
    size: chance.weighted(SIZES, [1, 2, 3, 4, 5]),
    toppings: chance.weighted(TOPPINGS, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
    total: parseFloat(chance.normal({ mean: 20, dev: 3 }).toFixed(2))
  };

  // Print the order to the console
  console.log(receipt);

  // Insert the order into MongoDB
  salesData
    .insertOne(receipt)
    .then(() =>
      // Wait then recursively generate a new receipt
      randomDelay(generateReceipts)
    )
    .catch(err =>
      console.error("\nERROR", err.json.errorCode, " ", err.json.error)
    );
}

function randomDelay(fn) {
  // Wait for a random amount of time before executing the given function
  setTimeout(fn, chance.integer({ min: 0, max: 1000 }));
}
