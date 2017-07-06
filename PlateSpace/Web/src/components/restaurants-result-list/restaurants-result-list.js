import React from 'react';

import RestaurantResultItem from '../restaurant-result-item';
import ReactScrollPagination from 'react-scroll-pagination';

const styles = {
  container: {
    width: '616px',
    flexWrap: 'wrap',
    display: 'flex',
    justifyContent: 'space-between',
    userSelect: 'none',
    cursor: 'default'
  }
};

const toRestaurantsItem = (item, index, props) =>
  <RestaurantResultItem
    onClick={props.onClick}
    key={index}
    {...item}
    title={`${item.name}`}
    distance={`${item.distance} miles`}
    style={{ marginBottom: '20px' }}
  />;

const RestaurantResultList = props => {
  const restaurantItems = props.restaurants.map((item, index) =>
    toRestaurantsItem(item, index, props)
  );

  return (
    <div style={{ ...styles.container, ...props.style }}>
      {restaurantItems}
      <ReactScrollPagination fetchFunc={props.fetchFunc} triggerAt={500} />
    </div>
  );
};

RestaurantResultList.propTypes = {
  restaurants: React.PropTypes.array.isRequired,
  onClick: React.PropTypes.func
};

export default RestaurantResultList;
