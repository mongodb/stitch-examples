import React from 'react';

import ImageWithPlaceholder from '../image-with-placeholder';
import restaurantImgPlaceholder from '../../assets/images/placeholder.png';
import Info from './info';

const styles = {
  container: {
    display: 'flex',
    marginTop: '20px'
  },
  infoStyle: {
    marginLeft: '40px'
  },
  imageContainer: {
    width: '183px',
    height: '183px',
    cursor: 'contex-menu',
    marginLeft: '22px',
    borderRadius: '10px'
  },
  image: {
    width: '183px',
    height: '183px',
    borderRadius: '10px'
  }
};

const DetailsHeader = props =>
  <div style={styles.container}>
    <ImageWithPlaceholder
      imageStyle={styles.image}
      style={styles.imageContainer}
      src={props.imgSource}
      placeholder={restaurantImgPlaceholder}
    />
    <Info {...props} />
  </div>;

export default DetailsHeader;
