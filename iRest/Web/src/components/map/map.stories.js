import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { Localization } from '../../localization';
import { mocks } from '../../storybook-mocks';
import Map from './map';

storiesOf('Map View', module)
  .add('With markers', () =>
    <Map
      defaultZoom={14}
      style={{
        width: '618px',
        height: '507px',
        borderRadius: '10px',
        overflow: 'hidden'
      }}
      markers={mocks.restaurantes}
      defaultCenter={{ lng: -74.007954, lat: 40.743209 }}
      onMarkerClick={action('marker clicked')}
      markersWithHover={true}
    />
  )
  .add('Without markers', () =>
    <Map
      defaultZoom={14}
      style={{
        width: '618px',
        height: '507px',
        borderRadius: '10px',
        overflow: 'hidden'
      }}
      defaultCenter={{ lng: -74.007954, lat: 40.743209 }}
      onMarkerClick={action('marker clicked')}
    />
  );
