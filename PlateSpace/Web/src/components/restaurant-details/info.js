import React from 'react';
import Title from './title';
import RateDisplay from './rate-display';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import Divider from '../divider';
import InfoDetailsLabel from './info-details-labels';

const styles = {
  container: {
    marginLeft: '40px',
    width: '352px',
    height: '100px'
  },
  leftAndRight: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  distance: {
    ...CommonStyles.divWithEllipsis,
    width: '90px',
    ...CommonStyles.textNormal,
    color: Colors.pumpkinOrange,
    fontSize: '14px',
    textAlign: 'right'
  },
  reviews: {
    ...CommonStyles.textNormal,
    color: Colors.grey,
    fontSize: '12px',
    opacity: 0.5
  }
};

const TitleDistanceContainer = props =>
  <div style={styles.leftAndRight}>
    <Title {...props} />
    <div style={styles.distance}>{`${props.distance} miles`}</div>
  </div>;

const RateReviewsContainer = props =>
  <div style={styles.leftAndRight}>
    <RateDisplay {...props} />
    <div style={styles.reviews}>{`${props.reviewsNumber} Ratings`}</div>
  </div>;

const Info = props =>
  <div style={styles.container}>
    <TitleDistanceContainer {...props} />
    <RateReviewsContainer {...props} />
    <Divider style={{ width: '352px', marginBottom: '11px' }} />
    <InfoDetailsLabel {...props} />
    <div style={{ width: '576px', height: '183px' }} />
  </div>;

export default Info;
