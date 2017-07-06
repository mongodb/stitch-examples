import React from 'react';
import Radium from 'radium';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  button: {
    borderRadius: '45px 45px 45px 45px',
    textAlign: 'center',
    display: 'flex',
    flexDirection: 'center',
    justifyContent: 'center',
    cursor: 'pointer'
  },
  buttonLabel: {
    ...CommonStyles.textBold,
    color: Colors.white,
    fontSize: '12px',
    letterSpacing: '1px',
    fontStrech: 'normal',
    cursor: 'pointer',
    alignSelf: 'center'
  }
};

const CustomButton = props => {
  return (
    <div onClick={props.onClick} style={{ ...styles.button, ...props.style }}>
      <label style={{ ...styles.buttonLabel, ...props.labelStyle }}>
        {props.label}
      </label>
    </div>
  );
};

export default Radium(CustomButton);
