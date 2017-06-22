import React from 'react';
import FlatButton from 'material-ui/FlatButton';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  navigationButton: {
    border: 'solid 1px #e64a19',
    borderRadius: '40px',
    height: '40px',
    width: '112px'
  },
  navigationMessage: {
    width: '194px',
    height: '20px',
    opacity: 0.5,
    ...CommonStyles.textNormal,
    color: Colors.black,
    userSelect: 'none',
    cursor: 'default',
    fontSize: '12px'
  },
  navigationContainer: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: '20px'
  },
  navigationLabelButton: {
    ...CommonStyles.textBold,
    fontSize: '12px',
    color: Colors.tomato,
    letterSpacing: '1px'
  }
};

const NavigationContainer = props =>
  <div style={styles.navigationContainer}>
    <div style={styles.navigationMessage}>{props.navigationMessage}</div>
    <FlatButton
      onClick={props.onNavButtonClick}
      style={styles.navigationButton}
      label={props.navigationButtonText}
      labelStyle={styles.navigationLabelButton}
    />
  </div>;

export default NavigationContainer;
