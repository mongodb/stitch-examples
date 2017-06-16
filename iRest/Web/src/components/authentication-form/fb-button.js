import React from 'react';
import Radium from 'radium';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import fbIcon from '../../assets/images/ic-facebook.png';

const styles = {
  container: {
    ...CommonStyles.blueElipseButton,
    display: 'flex',
    flexDireciton: 'row',
    alignItems: 'center',
    cursor: 'pointer',
    color: Colors.white,
    letterSpacing: '1px'
  },
  text: {
    marginLeft: '33px',
    height: '14px'
  },
  logo: {
    marginLeft: '25px'
  },
  divider: {
    marginLeft: '18px',
    width: '1px',
    height: '20px',
    opacity: 0.2,
    backgroundColor: Colors.white
  }
};

const FbButton = props =>
  <div onClick={props.onClick} style={{ ...styles.container, ...props.style }}>
    <img style={styles.logo} src={fbIcon} alt="fb icon" />
    <div style={styles.divider} />
    <div style={styles.text}> {props.buttonText} </div>
  </div>;

FbButton.propTypes = {
  buttonText: React.PropTypes.string,
  style: React.PropTypes.object,
  onClick: React.PropTypes.func.isRequired
};

FbButton.defaultProps = {
  buttonText: 'facebook',
  buttonStyle: {}
};

export default Radium(FbButton);
