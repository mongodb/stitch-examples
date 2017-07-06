import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';

const styles = {
  value: {
    ...CommonStyles.divWithEllipsis,
    width: '100px',
    ...CommonStyles.textNormal,
    fontSize: '8px',
    color: Colors.grey,
    opacity: 0.7,
    cursor: 'pointer'
  },
  infoContainer: {
    marginTop: '5px',
    cursor: 'pointer'
  }
};

const Info = props =>
  <div style={styles.infoContainer}>
    <div style={styles.value}>{props.address}</div>
    <div style={styles.value}>{props.phone}</div>
    <div style={styles.value}>{Localization.RESTAURANT_INFO.OPEN_HOURS}:</div>
    <div style={styles.value}>{props.openHours}</div>
  </div>;

export default Info;
