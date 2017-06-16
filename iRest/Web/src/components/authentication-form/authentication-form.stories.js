import React from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import { Localization } from '../../localization';
import { mocks } from '../../storybook-mocks';
import LoginForm from './login-form';
import CreateAccountForm from './create-account-form';

storiesOf('Authentication Form', module)
  .add('Log in', () =>
    <LoginForm
      onAuthButtonClick={action('auth button clicked')}
      onFbButtonClick={action('auth fb button clicked')}
      onNavButtonClick={action('auth nav button clicked')}
      onSkipButtonClick={action('auth skip button clicked')}
      navigationButtonText={Localization.LOGIN_FORM.NAVIGATION_BUTTON_TEXT}
      navigationMessage={Localization.LOGIN_FORM.NAVIGATION_MESSAGE}
      title={Localization.LOGIN_FORM.TITLE}
      authButtonText={Localization.LOGIN_FORM.BUTTON_TEXT}
    />
  )
  .add('Create an account', () =>
    <CreateAccountForm
      onAuthButtonClick={action('auth button clicked')}
      onFbButtonClick={action('auth fb button clicked')}
      onNavButtonClick={action('auth nav button clicked')}
      onSkipButtonClick={action('auth skip button clicked')}
      navigationButtonText={Localization.CREATE_FORM.NAVIGATION_BUTTON_TEXT}
      navigationMessage={Localization.CREATE_FORM.NAVIGATION_MESSAGE}
      title={Localization.CREATE_FORM.TITLE}
      authButtonText={Localization.CREATE_FORM.BUTTON_TEXT}
    />
  );
