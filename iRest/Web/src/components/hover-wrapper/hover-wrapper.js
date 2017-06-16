import React from 'react';

const HoverWrapper = props =>
  <div onMouseEnter={props.turnOn} onMouseLeave={props.turnOff}>
    {props.children}
  </div>;

export default HoverWrapper;
