import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { mocks } from '../../storybook-mocks';
import AuthenticationHeader from './authentication-header';
import { Localization } from '../../localization';

storiesOf('Authentication Header', module).add('header', () =>
  <AuthenticationHeader
    title={Localization.AUTHENTICATION_HEADER.TITLE}
    subTitle={Localization.AUTHENTICATION_HEADER.SUB_TITLE}
  />
);
