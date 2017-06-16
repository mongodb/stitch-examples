import React from 'react';
import { Localization } from '../../localization';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  noData: {
    ...CommonStyles.textNormal,
    color: Colors.white,
    fontSize: '12px',
    marginLeft: '25px',
    userSelect: 'none',
    cursor: 'default'
  }
};

const NoFiltersLabel = () =>
  <label style={styles.noData}>{Localization.HEADER.NO_FILTER}</label>;

export default NoFiltersLabel;
