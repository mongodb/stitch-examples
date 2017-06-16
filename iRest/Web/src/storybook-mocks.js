export const mocks = {
  session: {
    authToken: '121',
    userId: '1'
  },
  filters: [
    {
      id: 'WIFI',
      toggled: true
    },
    {
      id: 'OPEN_ON_WEEKENDS',
      toggled: false
    },
    {
      id: 'PARKING',
      toggled: true
    },
    {
      id: 'VEGETARIAN',
      toggled: false
    }
  ],
  restaurantes: [
    {
      id: '1',
      imgSource:
        'http://www.pdcdc.org/wp-content/uploads/2016/03/restaurant-939435_960_720.jpg',
      lng: -74.007954,
      lat: 40.743209,
      name: '2. Del PostoPostoPostoPostoPosto',
      address: 'address.1 address.1 address.1 address.1',
      phone: '123-456789 123-456789 123-456789 123-456789',
      distance: 123121328,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'http://www.delposto.com',
      reviewsNumber: 160
    },
    {
      id: '2',
      imgSource:
        'http://reliablewater247.com/wp-content/uploads/2015/05/restaurant-738788_960_720.jpg',
      lng: -73.99952,
      lat: 40.731654,
      name: 'title number 2',
      address: 'address.2',
      phone: '987-654321',
      distance: 1,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 190
    },
    {
      id: '3',
      imgSource:
        'http://www.alain-passard.com/wp-content/uploads/2016/01/Salle-Arpege-S-Delpech.jpg',
      lng: -73.996943,
      lat: 40.73397,
      name: 'title number 3',
      address: 'address.3',
      phone: '987-123456',
      distance: 15,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 150
    },
    {
      id: '4',
      imgSource:
        'http://www.pdcdc.org/wp-content/uploads/2016/03/restaurant-939435_960_720.jpg',
      lng: -74.007254,
      lat: 40.742209,
      name: '2. Del Posto',
      address: 'address.1',
      phone: '123-456789',
      distance: 8,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'http://www.delposto.com',
      reviewsNumber: 160
    },
    {
      id: '5',
      imgSource:
        'http://reliablewater247.com/wp-content/uploads/2015/05/restaurant-738788_960_720.jpg',
      lng: -73.99352,
      lat: 40.733654,
      name: 'title number 2',
      address: 'address.2',
      phone: '987-654321',
      distance: 1,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 190
    },
    {
      id: '6',
      imgSource:
        'http://www.alain-passard.com/wp-content/uploads/2016/01/Salle-Arpege-S-Delpech.jpg',
      lng: -73.993943,
      lat: 40.73394,
      name: 'title number 3',
      address: 'address.3',
      phone: '987-123456',
      distance: 15,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 150
    },
    {
      id: '7',
      imgSource:
        'http://www.pdcdc.org/wp-content/uploads/2016/03/restaurant-939435_960_720.jpg',
      lng: -74.007154,
      lat: 40.741209,
      name: '2. Del Posto',
      address: 'address.1',
      phone: '123-456789',
      distance: 8,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'http://www.delposto.com',
      reviewsNumber: 160
    },
    {
      id: '8',
      imgSource:
        'http://reliablewater247.com/wp-content/uploads/2015/05/restaurant-738788_960_720.jpg',
      lng: -73.99252,
      lat: 40.732654,
      name: 'title number 2',
      address: 'address.2',
      phone: '987-654321',
      distance: 1,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 190
    },
    {
      id: '9',
      imgSource:
        'http://www.alain-passard.com/wp-content/uploads/2016/01/Salle-Arpege-S-Delpech.jpg',
      lng: -73.990943,
      lat: 40.73097,
      name: 'title number 3',
      address: 'address.3',
      phone: '987-123456',
      distance: 15,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'www.delposto.com',
      reviewsNumber: 150
    },
    {
      id: '10',
      imgSource:
        'http://www.pdcdc.org/wp-content/uploads/2016/03/restaurant-939435_960_720.jpg',
      lng: -74.017954,
      lat: 40.753209,
      name: '2. Del Posto',
      address: 'address.1',
      phone: '123-456789',
      distance: 8,
      openHours: '09:00pm - 11:00am',
      foodType: 'Italian Food',
      web: 'http://www.delposto.com',
      reviewsNumber: 160
    }
  ],
  reviews: [
    {
      id: '1',
      name: 'Gal',
      authorId: '12',
      rateValue: 4,
      date: new Date(),
      text: 'some review'
    },
    {
      id: '2',
      name: 'John Smite',
      authorId: '2',
      rateValue: 4,
      date: new Date(),
      text:
        'My boyfriend called to make a reservation but was told it was by walk ins only. When we arrived, there was a line already forming. You have to stand in line to place your order, and then you can find a seat. My boyfriend and I stood in line until it was our turn to order and then we found a seat. It was disrespectful how people in the back of the line cut the line and saved a seat before ordering.'
    },
    {
      id: '3',
      name: 'John Smite',
      rateValue: 4,
      authorId: '3',
      date: new Date(),
      text:
        'My boyfriend called to make a reservation but was told it was by walk ins only. When we arrived, there was a line already forming. You have to stand in line to place your order, and then you can find a seat. My boyfriend and I stood in line until it was our turn to order and then we found a seat. It was disrespectful how people in the back of the line cut the line and saved a seat before ordering.'
    },
    {
      id: '4',
      name: 'John Smite',
      authorId: '4',
      rateValue: 4,
      date: new Date(),
      text:
        'My boyfriend called to make a reservation but was told it was by walk ins only. When we arrived, there was a line already forming. You have to stand in line to place your order, and then you can find a seat. My boyfriend and I stood in line until it was our turn to order and then we found a seat. It was disrespectful how people in the back of the line cut the line and saved a seat before ordering.'
    }
  ]
};
