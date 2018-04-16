exports = function(recipient, code) {
    var twilio = context.services.get("tw1");
    twilio.send({
        from: context.values.get("ourNumber"),
        to: recipient,
        body: "Your confirmation code is " + code
    });
}