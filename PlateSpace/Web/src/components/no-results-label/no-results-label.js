import React from 'react';

import { Localization } from '../../localization';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';

const styles = {
  container: {
    ...CommonStyles.textNormal,
    fontSize: '16px',
    color: Colors.black,
    opacity: 0.5,
    width: '616px',
    height: '616px',
    alignItems: 'center',
    display: 'flex',
    justifyContent: 'center'
  }
};

const NoResultsLabel = () =>
  <div style={styles.container}>
    {Localization.RESTAURANT_LIST_RESULTS.NO_RESULTS_LABEL}
  </div>;

export default NoResultsLabel;
