import React from 'react';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  container: {
    display: 'flex',
    width: '618px',
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  title: {
    ...CommonStyles.textNormal,
    color: Colors.black,
    opacity: 0.5,
    fontSize: 12
  },
  button: {
    ...CommonStyles.textNormal,
    color: Colors.tomato,
    fontSize: 12,
    cursor: 'pointer'
  }
};

const SubHeader = props =>
  <div style={{ ...styles.container, ...props.style }}>
    <label style={styles.title}>{props.title}</label>
    {props.button ||
      <label style={styles.button} onClick={props.onButtonClick}>
        {props.buttonLabel}
      </label>}
  </div>;

SubHeader.propTypes = {
  title: React.PropTypes.string.isRequired,
  onButtonClick: React.PropTypes.func.isRequired,
  buttonLabel: React.PropTypes.string.isRequired
};

export default SubHeader;
