import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { mocks } from '../../storybook-mocks';
import RestaurantsList from './restaurants-result-list';

storiesOf('Restaurants List Results', module).add('Results', () =>
  <RestaurantsList
    onClick={action('item clicked')}
    restaurants={mocks.restaurantes}
    fetchFunc={action('fetch')}
  />
);
