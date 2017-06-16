import React from 'react';

import { Localization } from '../../../localization';
import AuthenticationForm from '../authentication-form';

const CreateAccountForm = props =>
  <AuthenticationForm
    {...props}
    navigationButtonText={Localization.CREATE_FORM.NAVIGATION_BUTTON_TEXT}
    navigationMessage={Localization.CREATE_FORM.NAVIGATION_MESSAGE}
    title={Localization.CREATE_FORM.TITLE}
    authButtonText={Localization.CREATE_FORM.BUTTON_TEXT}
  />;

CreateAccountForm.propTypes = {
  onAuthButtonClick: React.PropTypes.func.isRequired,
  onFbButtonClick: React.PropTypes.func.isRequired,
  onNavButtonClick: React.PropTypes.func.isRequired,
  onSkipButtonClick: React.PropTypes.func.isRequired
};

export default CreateAccountForm;
