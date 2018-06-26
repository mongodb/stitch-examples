exports = function(phoneNumber){
  let finalNumber;
  const atlas = context.services.get("mongodb-atlas");
  const twoFactorCodes = atlas.db("quickstart").collection("2fa");
  const twilio = context.services.get("twilio");
  const formatNumber = number => context.functions.execute("lookupPhoneNumber", number).then(response => {
    return EJSON.parse(response.body.text()).phone_number;
  });
  const code = generateDeviceCode();
  
  
  // Store the code in MongoDB then send it to the user in a text message
  return formatNumber(phoneNumber)
    .then(formattedNumber => {
      finalNumber = formattedNumber;
      return linkCodeWithPhoneNumber(code, formattedNumber, twoFactorCodes);
    })
    .then(() => twilio.send({
      to: finalNumber,
      from: context.values.get("ourPhoneNumber"),
      body: `Your Stitch 2fa code is: ${code}`
    }));

  function generateDeviceCode() {
  // Generate a 6-digit 2fa code
    const genCodePart = () => {
      const part = Math.floor(Math.random() * 1000);
      return part.toString().padStart(3, 0);
    };
    const code = genCodePart(3) + genCodePart(3);
    return code;
  }

  function linkCodeWithPhoneNumber(code, phoneNumber, collection) {
  // Update or insert the document for the submitted phone number.
  // The document has information on the most recent 2fa code for a
  // phone number, including when the code was generated.
    const twoFactorCodes = collection;
    
    return twoFactorCodes.updateOne(
      { "phoneNumber": phoneNumber },
      { $set: { current2fa: { "code": code, "time": Date.now() } } },
      { "upsert": true }
    );
  }
  
};



// padStart polyfill

// https://github.com/uxitten/polyfill/blob/master/string.polyfill.js
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/padStart
if (!String.prototype.padStart) {
  String.prototype.padStart = function padStart(targetLength,padString) {
      targetLength = targetLength>>0; //truncate if number or convert non-number to 0;
      padString = String((typeof padString !== 'undefined' ? padString : ' '));
      if (this.length > targetLength) {
          return String(this);
      }
      else {
          targetLength = targetLength-this.length;
          if (targetLength > padString.length) {
              padString += padString.repeat(targetLength/padString.length); //append to original to ensure we are longer than needed
          }
          return padString.slice(0,targetLength) + String(this);
      }
  };
}