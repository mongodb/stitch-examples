import React from 'react';

import { Localization } from '../../localization';
import SubHeader from '../../components/sub-header';
import RestaurantResultList from '../../components/restaurants-result-list';

const ListWithResults = props =>
  <div>
    <SubHeader
      style={{ marginTop: '20px' }}
      title={Localization.SUB_HEADER.TITLE}
      onButtonClick={props.buttonHeaderClick}
      buttonLabel={Localization.SUB_HEADER.LIST_BUTTON_LABEL}
    />
    <RestaurantResultList
      style={{ marginTop: '10px' }}
      onClick={props.onItemClicked}
      fetchFunc={props.fetchFunc}
      restaurants={props.restaurants}
    />
  </div>;

export default ListWithResults;
