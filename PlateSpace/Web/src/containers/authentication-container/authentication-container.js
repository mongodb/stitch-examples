import React, { Component } from 'react';

import AuthenticationHeader from '../../components/authentication-header';
import LoginForm from '../../components/authentication-form/login-form';
import CreateAccountForm from '../../components/authentication-form/create-account-form';
import { Localization } from '../../localization';
import { Colors } from '../../commons/common-styles/common-styles';
import { MongoDbManager } from '../../mongodb-manager';
import MessageDialog from '../../components/dialogs/message-dialog';
import LoadingIndication from '../../components/loading-indication';

const styles = {
  container: {
    backgroundColor: Colors.lightGrey,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center'
  },
  forms: {
    marginTop: '20px',
    marginBottom: '20px'
  }
};

const Content = props =>
  <div>
    {props.showLogin &&
      <LoginForm
        style={styles.forms}
        onAuthButtonClick={props.login}
        onFbButtonClick={props.continueWithFacebook}
        onNavButtonClick={props.replaceView}
        onSkipButtonClick={props.skip}
        navigationButtonText={Localization.LOGIN_FORM.NAVIGATION_BUTTON_TEXT}
        navigationMessage={Localization.LOGIN_FORM.NAVIGATION_MESSAGE}
        title={Localization.LOGIN_FORM.TITLE}
        authButtonText={Localization.LOGIN_FORM.BUTTON_TEXT}
      />}
    {!props.showLogin &&
      <CreateAccountForm
        style={styles.forms}
        onAuthButtonClick={props.createAccount}
        onFbButtonClick={props.continueWithFacebook}
        onNavButtonClick={props.replaceView}
        onSkipButtonClick={props.skip}
        navigationButtonText={Localization.CREATE_FORM.NAVIGATION_BUTTON_TEXT}
        navigationMessage={Localization.CREATE_FORM.NAVIGATION_MESSAGE}
        title={Localization.CREATE_FORM.TITLE}
        authButtonText={Localization.CREATE_FORM.BUTTON_TEXT}
      />}
  </div>;

class AuthenticationContainer extends Component {
  constructor(props) {
    super(props);

    this.state = {
      showLogin: true,
      showMessage: false,
      messageDialogTitle: '',
      buttonDialogText: '',
      messageDialogText: '',
      stay: false,
      loading: false
    };

    this.replaceView = this.replaceView.bind(this);
    this.createAccount = this.createAccount.bind(this);
    this.login = this.login.bind(this);
    this.skip = this.skip.bind(this);
    this.continueWithFacebook = this.continueWithFacebook.bind(this);
    this.closeDialog = this.closeDialog.bind(this);
  }

  closeDialog() {
    this.setState({ showMessage: false });

    if (!this.state.stay) {
      this.props.router.replace('/restaurants');
    }
  }

  replaceView() {
    const { showLogin } = this.state;

    this.setState({ showLogin: !showLogin });
  }

  createAccount(email, password) {
    this.setState({ loading: true });
    MongoDbManager.createAccount(email, password)
      .then(result => {
        this.setState({
          showMessage: true,
          messageDialogTitle: Localization.CREATE_ACCOUNT.TITLE,
          buttonDialogText: Localization.CREATE_ACCOUNT.BUTTON,
          messageDialogText: Localization.CREATE_ACCOUNT.TEXT,
          stay: false,
          loading: false
        });
      })
      .catch(error => {
        this.setState({
          showMessage: true,
          messageDialogTitle: Localization.ERRORS.TITLE,
          messageDialogText: Localization.ERRORS.CREATE_ACCOUNT,
          buttonDialogText: Localization.ERRORS.BUTTON,
          stay: true,
          loading: false
        });
      });
  }

  login(email, password) {
    MongoDbManager.login(email, password)
      .then(result => {
        this.props.router.replace('/restaurants');
      })
      .catch(error => {
        this.setState({
          showMessage: true,
          messageDialogTitle: Localization.ERRORS.TITLE,
          messageDialogText: Localization.ERRORS.FAILED_LOGIN,
          buttonDialogText: Localization.ERRORS.BUTTON,
          stay: true,
          loading: false
        });
      });
  }

  skip() {
    MongoDbManager.loginAnonymous().then(() => {
      this.props.router.replace('/restaurants');
    });
  }

  continueWithFacebook() {
    MongoDbManager.loginWithFacebook();
  }

  render() {
    return (
      <div style={styles.container}>
        <AuthenticationHeader
          title={Localization.AUTHENTICATION_HEADER.TITLE}
          subTitle={Localization.AUTHENTICATION_HEADER.SUB_TITLE}
        />
        {this.state.loading && <LoadingIndication />}
        {!this.state.loading &&
          <Content
            login={this.login}
            continueWithFacebook={this.continueWithFacebook}
            replaceView={this.replaceView}
            skip={this.skip}
            createAccount={this.createAccount}
            showLogin={this.state.showLogin}
          />}
        <MessageDialog
          title={this.state.messageDialogTitle}
          open={this.state.showMessage}
          buttonText={this.state.buttonDialogText}
          onCancelClick={this.closeDialog}
          onOkClick={this.closeDialog}
          text={this.state.messageDialogText}
        />
      </div>
    );
  }
}

export default AuthenticationContainer;
