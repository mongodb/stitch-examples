import React, { Component } from 'react';

import { CommonStyles } from '../../../commons/common-styles/common-styles';
import StyledDialog from '../styled-dialog';

const styles = {
  textContainer: {
    ...CommonStyles.textNormal,
    fontSize: '12px',
    textAlign: 'center',
    opacity: 0.5,
    width: '293px',
    height: '40px',
    lineHeight: '1.67',
    paddingLeft: '65px'
  }
};
const MessageContainer = props =>
  <div style={styles.textContainer}>
    {props.text}
  </div>;

export default class MessageDialog extends Component {
  render() {
    return (
      <StyledDialog
        title={this.props.title}
        onCancelClick={this.props.onCancelClick}
        buttonText={this.props.buttonText}
        open={this.props.open}
        onOkClick={this.props.onOkClick}
        content={<MessageContainer text={this.props.text} />}
      />
    );
  }
}

MessageDialog.propTypes = {
  title: React.PropTypes.string.isRequired,
  open: React.PropTypes.bool.isRequired,
  buttonText: React.PropTypes.string.isRequired,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired,
  text: React.PropTypes.string.isRequired
};
