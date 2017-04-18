document.addEventListener('DOMContentLoaded', () => {
 
    'use strict'
 
    // Replace BAAS-APP-ID with your Application ID
    const baasClient = new baas.BaasClient("BAAS-APP-ID");
    const sendButton = document.getElementById('sendButton');

    // allow anonymous user access for this app
    function doAnonymousAuth() {
      const promise = baasClient.authManager.anonymousAuth(true);

      promise.then( result => {
        console.log("authenticated");
         
      }).catch( err => {
        console.error("Error performing auth", err)
      });
    }

    // execute pipeline when Send button is clicked
    sendButton.onclick = () => {

      var toEmail = document.getElementById("toEmail").value;
      var subject = document.getElementById("subject").value;
      var messageBody = document.getElementById("messageBody").value;

      // check to make sure there's a To: address
      if (toEmail != "") {

        baasClient.executePipeline([
          {
            // "http1" is the name of our HTTP service
            service:"http1",
            action:"post",
            let: {
              "auth": {
                "$concat": ["Bearer ", "$$values.sg-api-key"]
              }
            },
            args: {
              "url": "$$values.sg-url",
              "headers": {
                "Authorization": [ "$$vars.auth" ],
                "Content-Type": [ "application/json" ]
              },
              "body": {
                // include fields required by SendGrid
                "personalizations": [
                  {
                    "to": [{ "email": toEmail }]
                  }
                ],
                "from": {
                  "email": "$$values.my-email-address"
                },
                "subject": subject,
                "content": [
                  {
                    "type": "text/plain",
                    "value": messageBody
                  }
                ]
              }
            }
          }

        ]).then (function (result) {
          if (result) {
            // show a message for successful execution
            document.getElementById('jsonResponse').innerText = "Message successfuly sent to " + toEmail;
          }
        }).catch( err => {
          // possible errors: invalid URL, invalid API key, To address not on approved list
          document.getElementById('jsonResponse').innerText = "Message could not be sent. " + err;
        });

      } else {
        // no To address entered
        alert("Please enter an email address.");
      }
    }
 
    doAnonymousAuth()
 
});