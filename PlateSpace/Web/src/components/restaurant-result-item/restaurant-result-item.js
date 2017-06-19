import React from 'react';
import restaurantImgPlaceholder from '../../assets/images/placeholder.png';
import ImgWithPlaceholder from '../image-with-placeholder';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const content = {
  marginLeft: '13px',
  ...CommonStyles.textNormal,
  fontSize: '11px',
  color: Colors.grey,
  opacity: '0.7',
  cursor: 'pointer'
};

const styles = {
  container: {
    backgroundColor: Colors.white,
    height: '231px',
    width: '192px',
    borderRadius: '6.8px',
    userSelect: 'none',
    cursor: 'pointer'
  },
  header: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: '14px',
    marginLeft: '13px'
  },
  title: {
    ...CommonStyles.divWithEllipsis,
    width: '100px',
    ...CommonStyles.textBold,
    fontSize: '14px',
    color: Colors.black,
    cursor: 'pointer'
  },
  distance: {
    ...CommonStyles.divWithEllipsis,
    width: '50px',
    marginRight: '16px',
    ...CommonStyles.textNormal,
    fontSize: '11px',
    color: Colors.pumpkinOrange,
    cursor: 'pointer'
  },
  phone: {
    ...CommonStyles.divWithEllipsis,
    width: '100px',
    ...content,
    marginBottom: '12px'
  },
  address: {
    ...CommonStyles.divWithEllipsis,
    width: '85%',
    ...content,
    marginTop: '6px'
  },
  image: {
    width: '192px',
    height: '154px',
    borderTopLeftRadius: '6.8px',
    borderTopRightRadius: '6.8px'
  }
};

const RestaurantSummary = props =>
  <div style={{ cursor: 'pointer' }}>
    <div style={styles.header}>
      <div style={styles.title} title={props.title}>{props.title}</div>
      <div style={styles.distance}>{props.distance}</div>
    </div>
    <div style={styles.address} title={props.address}>{props.address}</div>
    <div style={styles.phone}>{props.phone}</div>
  </div>;

const RestaurantResultItem = props =>
  <div
    onClick={() => props.onClick(props.id)}
    style={{ ...styles.container, ...props.style }}
  >
    <ImgWithPlaceholder
      style={styles.image}
      imageStyle={styles.image}
      src={props.imgSource}
      placeholder={restaurantImgPlaceholder}
    />
    <RestaurantSummary {...props} />
  </div>;

RestaurantResultItem.propTypes = {
  id: React.PropTypes.string.isRequired,
  imgSource: React.PropTypes.string.isRequired,
  title: React.PropTypes.string.isRequired,
  distance: React.PropTypes.string.isRequired,
  address: React.PropTypes.string.isRequired,
  phone: React.PropTypes.string.isRequired
};

export default RestaurantResultItem;
