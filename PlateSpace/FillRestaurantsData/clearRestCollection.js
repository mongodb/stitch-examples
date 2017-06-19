var mongoose = require('mongoose');
var config = require('./config');

var restSchema = mongoose.Schema({
  name: String,
  address: String,
  phone: String,
  image_url: String,
  website: String,
  attributes: Object,
  location: Object,
  openingHours: Object,
  totalRate: Number,
  numberOfRates: Number
});

var Restaurant = mongoose.model('Restaurant', restSchema);

mongoose.connect(config.MONGO_URI);

Restaurant.collection.remove();