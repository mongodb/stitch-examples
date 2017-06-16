import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { Localization } from '../../localization';
import SubHeader from './sub-header';

storiesOf('Sub Header', module)
  .add('View on map', () =>
    <SubHeader
      title={Localization.SUB_HEADER.TITLE}
      onButtonClick={action('View on map clicked')}
      buttonLabel={Localization.SUB_HEADER.MAP_BUTTON_LABEL}
    />
  )
  .add('View on list', () =>
    <SubHeader
      title={Localization.SUB_HEADER.TITLE}
      onButtonClick={action('View as list clicked')}
      buttonLabel={Localization.SUB_HEADER.LIST_BUTTON_LABEL}
    />
  );
