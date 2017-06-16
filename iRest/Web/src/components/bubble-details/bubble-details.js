import React from 'react';

import ImageWithPlaceholder from '../image-with-placeholder/image-with-placeholder';
import restaurantImgPlaceholder from '../../assets/images/placeholder.png';
import { Colors } from '../../commons/common-styles/common-styles';
import Details from './details';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center'
  },
  triangleShap: {
    width: 0,
    height: 0,
    borderLeft: '10px solid transparent',
    borderRight: '10px solid transparent',
    borderTop: '10px solid white'
  },
  detailsContainer: {
    width: '210px',
    height: '76px',
    backgroundColor: Colors.white,
    boxShadow: '0 5px 10px rgba(0,0,0,0.3)',
    borderRadius: '10px',
    display: 'flex',
    flexDirection: 'row',
    cursor: 'pointer'
  },
  imageContainer: {
    width: '72px',
    height: '72px',
    margin: '2px',
    backgroundSize: 'contain',
    cursor: 'pointer'
  },
  image: {
    width: '72px',
    height: '72px',
    borderTopLeftRadius: '10px',
    borderBottomLeftRadius: '10px',
    borderTopRightRadius: '0px',
    borderBottomRightRadius: '0px',
    cursor: 'pointer'
  },
  details: {
    marginLeft: '8px',
    marginTop: '8px',
    cursor: 'pointer',
    userSelect: 'none'
  }
};

const BubbleDetails = props => {
  return (
    <div style={{ ...styles.container, ...props.style }}>
      <div style={styles.detailsContainer}>
        <ImageWithPlaceholder
          imageStyle={styles.image}
          style={styles.imageContainer}
          src={props.imgSource}
          placeholder={restaurantImgPlaceholder}
        />
        <Details {...props} style={styles.details} />
      </div>
      <div style={styles.triangleShap} />
    </div>
  );
};

Map.propTypes = {
  imgSource: React.PropTypes.string.isRequired,
  name: React.PropTypes.string.isRequired,
  distance: React.PropTypes.number.isRequired,
  address: React.PropTypes.string.isRequired,
  phone: React.PropTypes.string.isRequired,
  openHours: React.PropTypes.string.isRequired
};

export default BubbleDetails;
