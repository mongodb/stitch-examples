document.addEventListener('DOMContentLoaded', () => {

    'use strict'

    // Replace STITCH-APP-ID with your Application ID
    const stitchClient = new stitch.StitchClient("STITCH-APP-ID");
    const sendButton = document.getElementById('sendButton');

    // allow anonymous user access for this app
    function doAnonymousAuth() {
      stitchClient.authManager.anonymousAuth()
        .then( result => {
          console.log("authenticated");
        }).catch( err => {
          console.error("Error performing auth", err)
        });
    }

    // execute pipeline when Send button is clicked
    sendButton.onclick = () => {

      const toEmail = document.getElementById("toEmail").value;
      const subject = document.getElementById("subject").value;
      const messageBody = document.getElementById("messageBody").value;

      // check to make sure there's a To: address
      if (toEmail != "") {

        stitchClient.executePipeline([
          {
            // "http1" is the name of our HTTP service
            service:"http1",
            action:"post",
            let: {
              "sgUrl": "%%values.sg-url",
              "auth": {
                "%concat": ["Bearer ", "%%values.sg-api-key"]
              },
              "myEmail" : "%%values.my-email-address"
            },
            args: {
              "url": "%%vars.sgUrl",
              "headers": {
                "Authorization": [ "%%vars.auth" ],
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
                  "email": "%%vars.myEmail"
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
            document.getElementById('jsonResponse').innerText = "Message successfully sent to " + toEmail;
          }
        }).catch( err => {
          // possible errors: invalid URL, invalid API key, To address not on approved list
          document.getElementById('jsonResponse').innerText = "Message could not be sent. " + err;
        });

      } else {
        // no To address entered
        document.getElementById('jsonResponse').innerText = "Please enter an email address.";
      }
    }

    doAnonymousAuth()

});