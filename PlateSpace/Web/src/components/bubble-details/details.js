import React from 'react';
import Title from './title';
import Info from './info';

const Details = props =>
  <div style={props.style}>
    <Title {...props} />
    <Info {...props} />
  </div>;

export default Details;
