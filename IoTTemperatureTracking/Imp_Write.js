exports = function(data){
  //Get the current time
  var now = new Date();

  //Define Services and point to the correct Atlas collection
  //Uncomment the below when integrating with Dark Sky
  //var darksky = context.services.get("darksky");
  var mongodb = context.services.get("mongodb-atlas");
  var TempData = mongodb.db("Imp").collection("TempData");

  //Code for Dark Sky
  //var response = darksky.get({"url": "https://api.darksky.net/forecast/" + context.values.get("DarkSkyKey") + '/' + context.values.get("DeviceLocation")});
  //var darkskyJSON = EJSON.parse(response.body.text());

  var status =
    {
      "Timestamp": now.getTime(),
      "Date": now,
      "indoorTemp": data.temp*9/5+32,
      "indoorHumidity": data.humid
      //Data for Dark Sky – Uncomment and add a ',' on the above line.
      //"outdoorTemp": darkskyJSON.currently.temperature,
      //"outdoorHumidity": darkskyJSON.currently.humidity
    };

  return TempData.insertOne(status);
};
