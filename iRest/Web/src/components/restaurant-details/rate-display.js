import React from 'react';
import Chip from 'material-ui/Chip';
import Rate from 'rc-rate';
import 'rc-rate/assets/index.css';

import { Colors } from '../../commons/common-styles/common-styles';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'baseline'
  },
  chip: {
    width: '38px',
    height: '22px',
    display: 'flex',
    alignItems: 'center',
    marginRight: '10px'
  },
  chipLabel: {
    fontFamily: 'Sfns-Display-Regular',
    color: Colors.white,
    paddingLeft: '8px'
  },
  stars: {
    fontSize: '17px',
    marginBottom: '20px',
    userSelect: 'none'
  }
};
const RateDisplay = props =>
  <div style={styles.container}>
    <Chip
      style={styles.chip}
      labelStyle={styles.chipLabel}
      backgroundColor={Colors.trueGreen}
    >
      {Number(props.rateValue).toFixed(1)}
    </Chip>
    <Rate
      disabled
      allowHalf={true}
      defaultValue={Number(props.rateValue)}
      value={Number(props.rateValue)}
      style={styles.stars}
    />
  </div>;

export default RateDisplay;
