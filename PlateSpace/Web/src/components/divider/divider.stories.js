import React, { Component } from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import Divider from './divider';

storiesOf('Divider', module)
  .add('With split word', () =>
    <Divider splitWord="ok" style={{ width: '100px' }} />
  )
  .add('Without split word', () =>
    <Divider style={{ width: '180px', margin: '20px' }} />
  )
  .add('Default width style', () => <Divider style={{ margin: '20px' }} />);
