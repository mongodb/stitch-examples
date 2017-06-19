import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import DetailsHeader from './details-header';
import ReviewsHeader from './reviews-header';
import Map from '../map';
import Divider from '../divider';
import ReviewsList from '../reviews-list';

const styles = {
  container: {
    width: '620px',
    marginTop: '20px',
    backgroundColor: Colors.white,
    borderRadius: '10px'
  },
  map: {
    width: '576px',
    height: '183px',
    borderRadius: '10px',
    marginLeft: '22px',
    marginTop: '20px',
    overflow: 'hidden'
  },
  reviewsHeader: {
    marginTop: '30px',
    marginLeft: '42px'
  },
  noResults: {
    ...CommonStyles.textNormal,
    fontSize: '14px',
    color: Colors.black,
    opacity: 0.5,
    alignItems: 'center',
    display: 'flex',
    justifyContent: 'center',
    marginBottom: '50px',
    marginTop: '50px'
  }
};

const NoReviewsLabel = () =>
  <div style={styles.noResults}>
    {Localization.RESTAURANT_DETAILS.NO_REVIEWS_LABEL}
  </div>;

const HasReviews = props =>
  <ReviewsList
    style={{ marginLeft: '42px' }}
    reviews={props.reviews}
    editClick={props.editReviewClick}
  />;

const Reviews = props =>
  props.reviews.length > 0 ? <HasReviews {...props} /> : <NoReviewsLabel />;

const RestaurantDetails = props =>
  <div style={styles.container}>
    <DetailsHeader {...props} />
    <Map
      defaultZoom={14}
      {...props}
      style={styles.map}
      markers={[props]}
      defaultCenter={{ lng: props.lng, lat: props.lat }}
      markersWithHover={false}
    />
    <ReviewsHeader
      onButtonClick={props.addReviewClick}
      showButton={props.showAddReviewButton}
      style={styles.reviewsHeader}
    />
    <Divider
      style={{ width: '576px', marginTop: '12px', marginLeft: '22px' }}
    />
    <Reviews {...props} />
  </div>;

RestaurantDetails.propTypes = {
  imgSource: React.PropTypes.string.isRequired,
  name: React.PropTypes.string.isRequired,
  distance: React.PropTypes.number.isRequired,
  rateValue: React.PropTypes.string.isRequired,
  address: React.PropTypes.string.isRequired,
  phone: React.PropTypes.string.isRequired,
  web: React.PropTypes.string.isRequired,
  openHours: React.PropTypes.string.isRequired,
  reviews: React.PropTypes.array.isRequired,
  reviewsNumber: React.PropTypes.number.isRequired,
  showAddReviewButton: React.PropTypes.bool,
  addReviewClick: React.PropTypes.func,
  editReviewClick: React.PropTypes.func
};

export default RestaurantDetails;
