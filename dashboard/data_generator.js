const fetch = require('node-fetch');

const getPopularToppingsWebhook = "<YOUR WEBHOOK>"; // <webhook url>?secret=<secret>

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

generateReceipts();

function generateReceipts() {
  // Create a random pizza order
  const receipt = {
    timestamp: Date.now(),
    customerName: chance.name({ nationality: "en" }),
    cardNumber: chance.cc(),
    location: chance.weighted(LOCATIONS, [2, 5, 3]),
    size: chance.weighted(SIZES, [1, 2, 3, 4, 5]),
    topping: chance.weighted(TOPPINGS, [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]),
    total: parseFloat(chance.normal({ mean: 20, dev: 3 }).toFixed(2))
  };

  // Post the order to the addOrder webhook
  
  fetch(getPopularToppingsWebhook, {
    method: "POST",
    mode: "CORS",
    // The webhook handler expects the body to be stringified JSON
    body: JSON.stringify(receipt)
  })
    .then(response => response.json())
    .then(res => {
      // Log a successful order and generate another
      console.log(res);
      randomDelay(generateReceipts);
    })
    .catch(err => console.error(err));
}

function randomDelay(fn) {
  // Wait for up to one second before executing the given function
  setTimeout(fn, chance.integer({ min: 0, max: 4000 }));
}
