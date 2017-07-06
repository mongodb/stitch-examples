import React from 'react';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  leftAndRight: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '110px'
  },
  name: {
    ...CommonStyles.divWithEllipsis,
    width: '50px',
    ...CommonStyles.textBold,
    fontSize: '9.8px',
    color: Colors.black,
    cursor: 'pointer'
  },
  distance: {
    ...CommonStyles.divWithEllipsis,
    width: '45px',
    ...CommonStyles.textNormal,
    fontSize: '9.8px',
    color: Colors.pumpkinOrange,
    textAlign: 'right',
    cursor: 'pointer'
  }
};

const Title = props =>
  <div style={styles.leftAndRight}>
    <div style={styles.name}>{props.name}</div>
    <div style={styles.distance}>{`${props.distance} miles`}</div>
  </div>;

export default Title;
