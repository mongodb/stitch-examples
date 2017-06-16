import React from 'react';
import Radium from 'radium';

import { CommonStyles } from '../../../commons/common-styles/common-styles';
import icClose from '../../../assets/images/ic-close-normal.png';
import icCloseHover from '../../../assets/images/ic-close-hover.png';
import icClosePressed from '../../../assets/images/ic-close-pressed.png';

const styles = {
  container: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    height: '80px'
  },
  title: {
    ...CommonStyles.textNormal,
    fontSize: '26px',
    opacity: '0.5',
    textAlign: 'center'
  },
  closeIc: {
    cursor: 'pointer',
    userSelect: 'none',
    position: 'absolute',
    top: 0,
    right: 0,
    marginTop: '16px',
    padding: '16px',
    backgroundRepeat: 'no-repeat',
    backgroundImage: `url(${icClose})`,
    ':hover': {
      backgroundImage: `url(${icCloseHover})`
    },
    ':active': {
      backgroundImage: `url(${icClosePressed})`
    }
  }
};

const Title = props =>
  <div style={styles.container}>
    <div style={styles.title}> {props.text} </div>
    <div onClick={props.onCloseClick} style={styles.closeIc} />

  </div>;

Title.propTypes = {
  text: React.PropTypes.string.isRequired,
  onCloseClick: React.PropTypes.func.isRequired
};

export default Radium(Title);
