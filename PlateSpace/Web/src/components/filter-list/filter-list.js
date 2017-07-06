import React from 'react';

import FilterButton from './filter-button';

const styles = {
  listContainer: {
    width: '336px',
    height: '101px',
    display: 'flex',
    flexWrap: 'wrap',
    flexDirection: 'row',
    justifyContent: 'space-around'
  }
};

const FilterList = props => {
  const list = props.filters.map(filter =>
    <FilterButton
      key={filter.id}
      {...filter}
      filterChanged={props.filterChanged}
    />
  );

  return (
    <div style={styles.listContainer}>
      {list}
    </div>
  );
};

FilterList.propTypes = {
  filters: React.PropTypes.array.isRequired,
  filterChanged: React.PropTypes.func.isRequired
};

export default FilterList;
