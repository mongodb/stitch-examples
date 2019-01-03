async function getDarkSkyData() {
  // Get the current temperature from Dark Sky
  const DarkSky = context.services.get("DarkSky");
  const darkSkyKey = context.values.get("DarkSkyKey");
  const deviceLocation = context.values.get("DeviceLocation");
  const url = `https://api.darksky.net/forecast/${darkSkyKey}/${deviceLocation}`;

  const darkSkyResponse = await DarkSky.get({ url });
  return EJSON.parse(darkSkyResponse.body.text())
}

exports = async function (impData) {
  const darkSkyData = await getDarkSkyData();

  // Prepare the temperature reading data
  const now = new Date();
  const temperatureData = {
    indoorTemp: impData.temp * 9 / 5 + 32, // Convert to Fahrenheit
    indoorHumidity: impData.humid,
    outdoorTemp: darkSkyData.currently.temperature,
    outdoorHumidity: darkSkyData.currently.humidity,
    timestamp: now.getTime(),
    date: now
  };

  // Insert the temperature data into MongoDB
  const mongodb = context.services.get("mongodb-atlas");
  const TempData = mongodb.db("Imp").collection("TempData");

  return TempData.insertOne(temperatureData);
};
