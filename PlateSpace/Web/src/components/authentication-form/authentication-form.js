import React from 'react';
import FlatButton from 'material-ui/FlatButton';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import FbButton from './fb-button';
import Divider from '../divider';
import EmailPasswordForm from './email-password-form';
import NavigationContainer from './navigation-container';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    width: '618px',
    height: '590px',
    alignItems: 'center',
    borderRadius: '10px',
    background: '#fff',
    userSelect: 'none',
    cursor: 'default'
  },
  title: {
    ...CommonStyles.textNormal,
    width: '335px',
    height: '48px',
    opacity: '0.5',
    fontSize: '26px',
    textAlign: 'center',
    color: Colors.black,
    marginBottom: '20px',
    marginTop: '20px'
  },
  skipButton: {
    width: '144px',
    height: '35px',
    margin: 0,
    marginBottom: '20px'
  },
  skipLabelButton: {
    ...CommonStyles.textBold,
    cursor: 'pointer',
    fontSize: '12px',
    opacity: 0.5
  }
};

const AuthenticationForm = props =>
  <div style={{ ...styles.container, ...props.style }}>
    <div style={styles.title}>{props.title}</div>
    <EmailPasswordForm
      onAuthButtonClick={props.onAuthButtonClick}
      authButtonText={props.authButtonText}
    />
    <Divider splitWord={Localization.AUTHENTICATION_FORM.OR} />
    <FbButton
      onClick={props.onFbButtonClick}
      style={{ marginBottom: '30px' }}
      buttonText={Localization.AUTHENTICATION_FORM.BUTTON_LOGIN_FB_TEXT}
    />
    <Divider />
    <NavigationContainer
      onNavButtonClick={props.onNavButtonClick}
      navigationButtonText={props.navigationButtonText}
      navigationMessage={props.navigationMessage}
    />
    <Divider />
    <FlatButton
      onClick={props.onSkipButtonClick}
      style={styles.skipButton}
      label={Localization.AUTHENTICATION_FORM.SKIP_BUTTON}
      labelStyle={styles.skipLabelButton}
    />
  </div>;

AuthenticationForm.propTypes = {
  onAuthButtonClick: React.PropTypes.func.isRequired,
  onFbButtonClick: React.PropTypes.func.isRequired,
  onNavButtonClick: React.PropTypes.func.isRequired,
  onSkipButtonClick: React.PropTypes.func.isRequired,
  title: React.PropTypes.string,
  authButtonText: React.PropTypes.string,
  navigationButtonText: React.PropTypes.string,
  navigationMessage: React.PropTypes.string
};

AuthenticationForm.defaultProps = {
  createMode: true,
  title: Localization.AUTHENTICATION_FORM.TITLE,
  authButtonText: Localization.AUTHENTICATION_FORM.BUTTON_TEXT,
  navigationButtonText: Localization.AUTHENTICATION_FORM.NAVIGATION_BUTTON_TEXT,
  navigationMessage: Localization.AUTHENTICATION_FORM.NAVIGATION_MESSAGE
};

export default AuthenticationForm;
