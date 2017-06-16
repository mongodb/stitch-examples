The purpose of the script is to fill new mongoDB with restaurants data using YelpAPI.


Getting Started:  
  1. Clone/download rep  
  2. Create new mongoDB  
  3. Register yelp as a developer for getting an auth token.
  4. Edit 'config.js' file:  
    - `MONGO_URI`: here you need to put your mongoDB connection string.
    - `YELP_AUTH_TOKEN`: here you need to put your auth token from Yelp.
  5. Install yarn using this link: https://yarnpkg.com/lang/en/docs/install/
  6. Install the following packages using yarn: 
  	- `yarn`
  7. Run command `node index.js`



The script creates new collection for restaurants, using YelpAPI.    
    
Collection schema:   
    ```{
      name: String,
      address: String,
      phone: String,
      image_url: String,
      website: String,
      attributes: Object,
      location: Object,
      openingHours: Object,
      averageRating: Number,
      numberOfRates: Number
    }
    ```

Please notice that 'attributes' and 'openingHours' fields, are not taken from Yelp and generate fake data.

In order to delete the collection, please run the following line:  
  - `node clearRestCollection.js`