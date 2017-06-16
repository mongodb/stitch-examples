import React from 'react';
import { Localization } from '../../localization';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  label: {
    ...CommonStyles.textBold,
    fontSize: '12px',
    color: Colors.mangoYellow,
    paddingLeft: '25px'
  }
};

const FilterLabel = props =>
  <label style={styles.label} key={props.id}>
    {Localization.FILTERS[props.id]}
    {' '}
  </label>;

export default FilterLabel;
