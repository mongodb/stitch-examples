exports = function(payload, response) {
  // Parse the webhook payload
  const formatPhoneNumber = () => context.functions.execute("lookupPhoneNumber", payload.From).then(response => {
    return EJSON.parse(response.body.text()).phone_number;
  });
  let [action, ...messageParts] = payload.Body.split(" ");
  action = action.toLowerCase();
  const message = messageParts.join(" ");
  
  // Connect to MongoDB Atlas
  const atlas = context.services.get("mongodb-atlas");
  const todos = atlas.db("quickstart").collection("messages");
  
  // Respond to the webhook payload
  if (message.length > 50) {
    response.setBody("Message is too long. Must be 50 characters or fewer.");
  }
  else if (action === "add") {
    formatPhoneNumber(payload.From)
      .then(fromPhone => {
        return todos.updateOne(
          { "phoneNumber": fromPhone },
          { "$push": { "messages": message } },
          { "upsert": true }
        );
      })
     .then(() => response.setBody("Successfully added your message!"));
  }
  else {
    let error = `Couldn't process action of type: ${action}. `;
    let advice = 'If you want to add a message, start your message with the word "add".';
    response.setBody(error + advice);
  }
  response.setStatusCode(201);
  response.addHeader("Content-Type", "text/plain");
};

