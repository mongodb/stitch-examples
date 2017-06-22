import React from 'react';

import { Localization } from '../../../localization';
import AuthenticationForm from '../authentication-form';

const LoginForm = props =>
  <AuthenticationForm
    {...props}
    navigationButtonText={Localization.LOGIN_FORM.NAVIGATION_BUTTON_TEXT}
    navigationMessage={Localization.LOGIN_FORM.NAVIGATION_MESSAGE}
    title={Localization.LOGIN_FORM.TITLE}
    authButtonText={Localization.LOGIN_FORM.BUTTON_TEXT}
  />;

LoginForm.propTypes = {
  onAuthButtonClick: React.PropTypes.func.isRequired,
  onFbButtonClick: React.PropTypes.func.isRequired,
  onNavButtonClick: React.PropTypes.func.isRequired,
  onSkipButtonClick: React.PropTypes.func.isRequired
};

export default LoginForm;
