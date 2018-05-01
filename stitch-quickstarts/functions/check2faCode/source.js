exports = function(phoneNumber, submittedCode){
  const atlas = context.services.get("mongodb-atlas");
  const twoFactorCodes = atlas.db("quickstart").collection("2fa");
  const formatPhoneNumber = number => context.functions.execute("lookupPhoneNumber", number)
    .then(response => EJSON.parse(response.body.text()).phone_number);
  
  return formatPhoneNumber(phoneNumber)
    .then(formattedNumber => {
      return twoFactorCodes.findOne({ phoneNumber: formattedNumber });
    })
    .then(doc => {
      const twoFactorCode = doc.current2fa.code;
      return twoFactorCode == submittedCode;
    });
};