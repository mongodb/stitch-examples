// Set-up the Stitch client
const stitch = require("mongodb-stitch");
// Add your App ID below
const stitchClientPromise = stitch.StitchClientFactory.create("<STITCH APP ID>");

// Send sample data while within this loop
function generateData(stitchClient){
  // Create a random temperature and humidity data point with
  // temp ranging from -20 to 20 °C
  const data = {
    "temp" : Math.floor(Math.random() * 20) - 20,
    "humid" : Math.floor(Math.random() * 100)
  };

  // Print to the console
  console.log(data);

  // Simulate write to MongoDB every 2 minutes
  stitchClient.executeFunction("Imp_Write", data).then(
    setTimeout(() => generateData(stitchClient), 120000)
  );
}

// Use the API Key to load data
stitchClientPromise.then(stitchClient => {
  return stitchClient.authenticate("apiKey", "<STITCH API KEY>").then(() => generateData(stitchClient));
})
