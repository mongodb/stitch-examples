import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  container: {
    marginBottom: '10px'
  },
  name: {
    ...CommonStyles.divWithEllipsis,
    width: '230px',
    ...CommonStyles.textBold,
    fontSize: '20px',
    color: Colors.black
  }
};

const Title = props =>
  <div style={styles.container}>
    <div style={styles.name} title={props.name}>{props.name}</div>
  </div>;

export default Title;
