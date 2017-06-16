import React from 'react';
import Dialog from 'material-ui/Dialog';

import { CommonStyles } from '../../../commons/common-styles/common-styles';
import Title from './title-dialog';
import CustomButton from '../../custom-button';

const styles = {
  container: {
    width: '473px',
    alignItems: 'center'
  },
  title: {
    ...CommonStyles.textNormal,
    fontSize: '26px',
    opacity: '0.5',
    textAlign: 'center'
  },
  button: {
    ...CommonStyles.redElipseButton,
    marginBottom: '61px',
    height: '45px'
  },
  actionsContainer: {
    display: 'flex',
    justifyContent: 'center'
  }
};

const StyledDialog = props => {
  const actions = [
    <CustomButton
      style={styles.button}
      onClick={props.onOkClick}
      label={props.buttonText}
    />
  ];

  return (
    <Dialog
      title={<Title onCloseClick={props.onCancelClick} text={props.title} />}
      actions={actions}
      modal={true}
      open={props.open}
      actionsContainerStyle={styles.actionsContainer}
      contentStyle={styles.container}
    >
      {props.content}
    </Dialog>
  );
};

StyledDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  title: React.PropTypes.string.isRequired,
  buttonText: React.PropTypes.string.isRequired,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired,
  content: React.PropTypes.object
};

export default StyledDialog;
