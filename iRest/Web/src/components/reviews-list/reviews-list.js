import React from 'react';

import ReviewItem from '../review-item';

const ReviewList = props => {
  const toReviewItem = props.reviews.map((item, index) =>
    <ReviewItem key={index} editClick={props.editClick} {...item} />
  );

  return <div style={props.style}>{toReviewItem}</div>;
};

export default ReviewList;
