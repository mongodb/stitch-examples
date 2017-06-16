import React, { Component } from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import CustomButton from '../custom-button';

const styles = {
  emailPasswordContainer: {
    display: 'flex',
    flexDirection: 'column',
    marginBottom: '30px',
    userSelect: 'none',
    cursor: 'default'
  },
  input: {
    ...CommonStyles.elipseInputStyle,
    paddingLeft: '20px',
    marginBottom: '10px',
    letterSpacing: '1px',
    color: Colors.black,
    outline: 'none'
  }
};

class EmailPasswordForm extends Component {
  constructor(props) {
    super(props);

    this.authClicked = this.authClicked.bind(this);
  }

  authClicked() {
    this.props.onAuthButtonClick(
      this.emailInput.value,
      this.passwordInput.value
    );
  }

  render() {
    return (
      <div style={styles.emailPasswordContainer}>
        <input
          ref={emailInput => (this.emailInput = emailInput)}
          style={styles.input}
          placeholder={Localization.AUTHENTICATION_FORM.EMAIL_PLACEHOLDER}
        />
        <input
          ref={passwordInput => (this.passwordInput = passwordInput)}
          type="password"
          style={styles.input}
          placeholder={Localization.AUTHENTICATION_FORM.PASSWORD_PLACEHOLDER}
        />
        <CustomButton
          style={CommonStyles.redElipseButton}
          onClick={this.authClicked}
          label={this.props.authButtonText}
        />
      </div>
    );
  }
}

export default EmailPasswordForm;
