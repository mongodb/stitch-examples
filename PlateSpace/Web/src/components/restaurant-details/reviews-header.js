import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import CustomButton from '../custom-button';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '556px'
  },
  title: {
    ...CommonStyles.textBold,
    color: Colors.black,
    opacity: 0.3,
    fontSize: '14px'
  },
  button: {
    ...CommonStyles.greenElipseButton,
    width: '83px',
    height: '22px',
    cursor: 'pointer'
  },
  buttonLabel: {
    ...CommonStyles.textNormal,
    color: Colors.white,
    fontSize: '10px',
    cursor: 'pointer'
  }
};

const ReviewsHeader = props =>
  <div style={{ ...styles.container, ...props.style }}>
    <div style={styles.title}>{Localization.REVIEWS_HEADER.TITLE}</div>

    {props.showButton &&
      <CustomButton
        onClick={props.onButtonClick}
        style={styles.button}
        labelStyle={styles.buttonLabel}
        label={Localization.REVIEWS_HEADER.BUTTON_TEXT}
      />}
  </div>;

ReviewsHeader.propType = {
  showButton: React.PropTypes.bool.isRequired,
  onButtonClick: React.PropTypes.func.isRequired
};

export default ReviewsHeader;
