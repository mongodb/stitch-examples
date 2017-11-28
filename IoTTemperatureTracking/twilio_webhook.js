exports = function(message){
  //Parse the date
  var userDate = new Date(message.Body.substring(5,message.Body.length));

  //Define Services and Collections
  var mongodb = context.services.get("mongodb-atlas");
  var TempData = mongodb.db("Imp").collection("TempData");
  var twilio = context.services.get("twilio");
  var responseMessage = "No weather data found";

  if(message.Body.toLowerCase() === "temp" || message.Body.toLowerCase() === "temp now"){
    var data = TempData.find().sort({"Timestamp" : -1}).limit(1).toArray();
    if (data.length === 1){
      responseMessage = "As of " + data[0].Date + " the indoor temperature was " + data[0].indoorTemp + "°F and the outdoor temperature was " + data[0].outdoorTemp + "°F.";
    }
  }else if(!isNaN(userDate.valueOf())){
    var data = TempData.find({"Timestamp" : {"$lte" : userDate.getTime()/1000}}).sort({"Timestamp" : -1}).limit(1).toArray();
    if (date.length === 1){
      responseMessage = "As of " + data[0].Date + " the indoor temperature was " + data[0].indoorTemp + "°F and the outdoor temperature was " + data[0].outdoorTemp + "°F.";
    }
  }else{
    responseMessage = "Invalid Request: Try \"Temp Now\" or \"Temp [Date]\"";
  }

  //Send the response
  return twilio.send({
    from : context.values.get("TwilioPhone"),
    to : message.From,
    body : responseMessage
  });
};
