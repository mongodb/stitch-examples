const appId = "<YOUR APP ID>";
const dashboardApiKey = "<YOUR STITCH API KEY>"; // API Key for the provider created in step C.4

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

// Create and authenticate a new StitchClient then begin generating data
stitch.StitchClientFactory.create(appId)
  .then(client => {
    stitchClient = client;
    salesData = stitchClient
      .service("mongodb", "mongodb-atlas")
      .db("SalesReporting")
      .collection("Receipts");

    return simpleAuth();
    // return apiKeyAuth()
  })
  .then(generateReceipts)
  .catch(err => console.error(err));

// Log in to Stitch with anonymous authentication
function simpleAuth() {
  return stitchClient.login();
}

// Authenticate with Stitch using an API Key
function apiKeyAuth(client) {
  return client.authenticate("apiKey", dashboardApiKey);
}

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
    // Delay before generating a new receipt
    .then(() => randomDelay(generateReceipts))
    .catch(err =>
      console.error("\nERROR", err.json.errorCode, " ", err.json.error)
    );
}

function randomDelay(fn) {
  // Wait for up to one second before executing the given function
  setTimeout(fn, chance.integer({ min: 0, max: 1000 }));
}
