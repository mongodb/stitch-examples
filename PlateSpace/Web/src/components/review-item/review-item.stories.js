import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { mocks } from '../../mocks';
import ReviewItem from './review-item';

storiesOf('Review item', module)
  .add('No edit', () => <ReviewItem {...mocks.reviews[1]} />)
  .add('With edit', () =>
    <ReviewItem
      {...mocks.reviews[0]}
      editable={true}
      onEditClick={action('edit clicked')}
    />
  );
