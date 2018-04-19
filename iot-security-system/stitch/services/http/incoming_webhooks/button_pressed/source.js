// Try running in the console below.
  
exports = function(payload) {
  const mongodb = context.services.get("mongodb-atlas");
  const http = context.services.get("http");
  
  const fppConfig = context.values.get("faceplusplus");

  const db = mongodb.db("security-system");
  var logEntryOID = payload.query.user + "-" + Date();
  var logEntry = { _id : logEntryOID, action : "button_pressed", args : payload.query };
  db.collection("log").insertOne( logEntry );
  
  db.collection("settings").findOne( { _id : payload.query.user } ).then( settings => {
    if (!settings) {
      console.log("cannot find user: " + payload.query.user);
      return;
    }
    
    db.collection("images").find( { owner_id : payload.query.user, active : true } ).toArray().then( images => {
      for ( var i = 0; i < images.length; i++ ) {
        let imgData = images[i].image;
        imgData = imgData.substring( imgData.indexOf( "base64" ) + 7);
        http.post( { url : "https://api-us.faceplusplus.com/facepp/v3/compare",
                     form : {
                      api_key : fppConfig.api_key,
                      api_secret : fppConfig.api_secret,
                      image_url1 : settings.camera_url,
                      image_base64_2 : imgData
                      //image_url2 : "https://www.mongodb.com/assets/images/leadership/Eliot-Horowitz.png"
                     }
        }).then( res => {
          if (res.statusCode != 200 ) {
            console.log("faceplusplus call failed:" + JSON.stringify(res));
            return;
          }
          res = JSON.parse(res.body.text());
          db.collection("log").updateOne( { _id : logEntryOID} , { $push : { "faceplusplus" : res } });

          if (res.confidence && res.confidence > 80 ) {
            http.post( { url : settings.unlock_url } );
            console.log("unlocked door");
          } else {
            console.log("HACKER!");
          }
          
        }).catch( err => { console.log("error in http call: " + err); }); 
      }
    }).catch( err => { console.log("error in image search callback: " + err ); });
  }).catch( err => { console.log("error in settings callback: " + err); }); 
    
};