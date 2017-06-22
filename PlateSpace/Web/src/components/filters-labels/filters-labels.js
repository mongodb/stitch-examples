import React from 'react';
import { Localization } from '../../localization';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import FilterLabel from './filter-label';
import NoFiltersLabel from './no-filters-label';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'baseline'
  },
  title: {
    ...CommonStyles.textNormal,
    fontSize: '12px',
    color: Colors.white,
    opacity: 0.7
  },
  editButton: {
    width: '66px',
    height: '24px',
    borderRadius: '35px',
    border: 'solid 1px #fff',
    marginLeft: '25px',
    paddingTop: '3px',
    userSelect: 'none',
    cursor: 'pointer'
  },
  buttonLabelStyle: {
    ...CommonStyles.textNormal,
    fontSize: '11px',
    color: Colors.white,
    paddingLeft: '20px',
    paddingTop: '17px',
    cursor: 'pointer'
  }
};

const FiltersLabels = props => {
  const filterListText = props.filters.length > 0
    ? props.filters.map(FilterLabel)
    : <NoFiltersLabel />;

  return (
    <div style={styles.container}>
      <div style={styles.title}> {props.title} </div>
      {filterListText}
      <div onClick={props.editButtonClicked} style={styles.editButton}>
        <label style={styles.buttonLabelStyle}>
          {Localization.HEADER.EDIT_BUTTON_TEXT}
        </label>
      </div>
    </div>
  );
};

FiltersLabels.propTypes = {
  filters: React.PropTypes.array.isRequired,
  editButtonClicked: React.PropTypes.func.isRequired
};

export default FiltersLabels;
