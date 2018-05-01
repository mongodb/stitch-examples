exports = function(phoneNumber){
  const host = "lookups.twilio.com";
  const path = `/v1/PhoneNumbers/${phoneNumber}`;
  const lookupUrl = `https://lookups.twilio.com/v1/PhoneNumbers/${phoneNumber}`;
  const http = context.services.get("http");
  
  const { SID, Secret } = context.values.get("twilioCredentials");
  
  return http.get({
    "scheme": "https",
    host,
    path,
    "username": SID,
    "password": Secret
  });
};