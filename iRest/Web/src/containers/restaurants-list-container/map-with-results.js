import React from 'react';

import { Localization } from '../../localization';
import SubHeader from '../../components/sub-header';
import Map from '../../components/map';

const styles = {
  map: {
    width: '618px',
    height: '507px',
    borderRadius: '10px',
    overflow: 'hidden',
    marginTop: '10px'
  }
};

const MapWithResults = props =>
  <div>
    <SubHeader
      style={{ marginTop: '20px' }}
      title={Localization.SUB_HEADER.TITLE}
      onButtonClick={props.buttonHeaderClick}
      buttonLabel={Localization.SUB_HEADER.MAP_BUTTON_LABEL}
    />
    <Map
      style={styles.map}
      defaultZoom={12}
      markers={props.restaurants}
      defaultCenter={{ lng: -73.901132, lat: 40.676676 }}
      onMarkerClick={props.onItemClicked}
      markersWithHover={true}
    />
  </div>;

export default MapWithResults;
