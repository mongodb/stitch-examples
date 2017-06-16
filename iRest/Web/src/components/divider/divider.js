import React from 'react';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  divider: {
    height: '1px',
    width: '140px',
    opacity: 0.1,
    backgroundColor: Colors.black
  },
  splitContainer: {
    display: 'flex',
    alignItems: 'center',
    height: '20px',
    marginBottom: '30px'
  },
  orDiv: {
    ...CommonStyles.textNormal,
    color: Colors.black,
    opacity: '0.5',
    fontSize: '12px',
    margin: '10px'
  }
};

const Divider = props =>
  props.splitWord
    ? <div style={styles.splitContainer}>
        <div style={{ ...styles.divider, ...props.style }} />
        <div style={styles.orDiv}>{props.splitWord}</div>
        <div style={{ ...styles.divider, ...props.style }} />
      </div>
    : <div
        style={{
          ...styles.divider,
          width: '320px',
          marginBottom: '30px',
          ...props.style
        }}
      />;

export default Divider;
