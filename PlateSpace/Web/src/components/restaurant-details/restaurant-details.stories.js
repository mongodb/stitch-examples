import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { mocks } from '../../storybook-mocks';
import RestaurantDetails from './restaurant-details';

storiesOf('Restaurant Details', module)
  .add('Edit', () =>
    <RestaurantDetails
      {...mocks.restaurantes[0]}
      rateValue="4.0"
      reviews={mocks.reviews}
      showAddReviewButton={false}
      addReview={action('add review clicked')}
    />
  )
  .add('Add', () =>
    <RestaurantDetails
      {...mocks.restaurantes[0]}
      rateValue="4.0"
      reviews={mocks.reviews.slice(1)}
      showAddReviewButton={true}
      addReview={action('add review clicked')}
    />
  );
