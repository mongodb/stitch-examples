import React from 'react';
import pressedPin from '../../assets/images/ic-location-pressed.png';
import WithHoverMarker from './with-hover-marker';

const styles = {
  pressedImg: {
    userSelect: 'none',
    cursor: 'default'
  }
};

const WithouthHoverMarker = props =>
  <img style={styles.pressedImg} alt="marker" src={pressedPin} />;

const CustomMarker = props =>
  props.withHover ? <WithHoverMarker {...props} /> : <WithouthHoverMarker />;

export default CustomMarker;
