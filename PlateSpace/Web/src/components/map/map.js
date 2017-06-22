import React from 'react';
import GoogleMap from 'google-map-react';
import Marker from '../custom-marker/custom-marker';

const Map = props => {
  const markers = props.markers.map((data, index) =>
    <Marker
      {...data}
      onClick={props.onMarkerClick}
      key={index}
      withHover={props.markersWithHover}
    />
  );

  return (
    <div style={props.style}>
      <GoogleMap
        bootstrapURLKeys={{
          key: 'AIzaSyDqvn5XeeBHmiokvcoR6NsgczMmCaq0Q20',
          language: 'en_US'
        }}
        center={props.defaultCenter}
        defaultZoom={props.defaultZoom}
      >
        {markers}
      </GoogleMap>
    </div>
  );
};

Map.propTypes = {
  markers: React.PropTypes.array.isRequired,
  defaultCenter: React.PropTypes.object.isRequired,
  markersWithHover: React.PropTypes.bool,
  defaultZoom: React.PropTypes.number
};

Map.defaultProps = {
  markersWithHover: false,
  defaultZoom: 12,
  markers: []
};

export default Map;
