import React from 'react';
import '../../assets/fonts/fonts.css';
import bgImage from '../../assets/images/header-image.png';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  container: {
    width: '100%',
    height: '213px',
    backgroundSize: 'cover',
    userSelect: 'none',
    cursor: 'default',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundImage: `url(${bgImage})`,
    backgroundRepeat: 'no-repeat'
  },
  title: {
    ...CommonStyles.textBold,
    fontSize: '70px',
    color: Colors.white
  },
  subTitle: {
    ...CommonStyles.textNormal,
    fontSize: '16px',
    color: Colors.white,
    opacity: 0.7
  }
};

const AuthenticationHeader = props =>
  <div style={styles.container}>
    <div style={styles.title}>{props.title}</div>
    <div style={styles.subTitle}>{props.subTitle}</div>
  </div>;

AuthenticationHeader.propTypes = {
  title: React.PropTypes.string,
  subTitle: React.PropTypes.string
};

export default AuthenticationHeader;
