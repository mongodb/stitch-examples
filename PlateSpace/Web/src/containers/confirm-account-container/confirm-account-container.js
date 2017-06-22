import React, { Component } from 'react';

import ConfirmAccountForm from '../../components/authentication-form/confirm-account-form';
import { Localization } from '../../localization';
import { Colors } from '../../commons/common-styles/common-styles';
import { MongoDbManager } from '../../mongodb-manager';
import MessageDialog from '../../components/dialogs/message-dialog';

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

class ConfirmAccountContainer extends Component {
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
    this.confirmAccount = this.confirmAccount.bind(this);
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

  confirmAccount() {
    var token = this.props.token;
    var tokenId = this.props.tokenId;
    console.log('confirm-account token and tokenId', this.props.token, this.props.tokenId)
    if(token && tokenId) {
      MongoDbManager.confirmAccount(tokenId, token)
      .then(result => {
        this.setState({
          showMessage: true,
          messageDialogTitle: Localization.CONFIRM_ACCOUNT.TITLE,
          buttonDialogText: Localization.CONFIRM_ACCOUNT.BUTTON,
          messageDialogText: Localization.CONFIRM_ACCOUNT.TEXT,
          stay: false,
          loading: false
        });
      })
      .catch(error => {
        console.log('error while confirming your account', error);
        this.setState({
          showMessage: true,
          messageDialogTitle: Localization.ERRORS.TITLE,
          messageDialogText: Localization.ERRORS.CONFIRM_ACCOUNT,
          buttonDialogText: Localization.ERRORS.BUTTON,
          stay: true,
          loading: false
        });
      });
    }
  }

  render() {
    return (
      <div style={styles.container}>
        <ConfirmAccountForm 
          onConfirmClick={this.confirmAccount}
          confirmButtonText={Localization.CONFIRM_FORM.BUTTON_TEXT}/>
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

export default ConfirmAccountContainer;
