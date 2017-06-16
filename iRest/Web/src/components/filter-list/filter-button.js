import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import CustomButton from '../custom-button';

const elipseButton = {
  borderRadius: '38px',
  height: '45px',
  width: '150px',
  display: 'flex',
  flexDirection: 'column',
  alignItems: 'center',
  marginBottom: '11px',
  cursor: 'pointer'
};

const label = {
  ...CommonStyles.textBold,
  fontSize: '12px',
  alignText: 'center',
  letterSpacing: 'normal',
  display: 'inline-block',
  width: '150px',
  cursor: 'pointer'
};

const styles = {
  nodeToggled: {
    ...elipseButton,
    border: 'solid 1px #e64a19'
  },
  nodeDefault: {
    ...elipseButton,
    border: 'solid 1px #000',
    opacity: 0.4
  },
  labelToggled: {
    ...label,
    color: Colors.tomato
  },
  labelDefault: {
    ...label,
    color: Colors.black
  }
};

const FilterButton = props => {
  const buttonStyle = props.toggled ? styles.nodeToggled : styles.nodeDefault;
  const labelStyle = props.toggled ? styles.labelToggled : styles.labelDefault;

  return (
    <CustomButton
      onClick={() => props.filterChanged(props.id)}
      key={props.id}
      style={buttonStyle}
      labelStyle={labelStyle}
      label={Localization.FILTERS[props.id]}
    />
  );
};

export default FilterButton;
