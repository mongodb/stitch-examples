import React from 'react';

import { Localization } from '../../../localization';
import ReviewDialog from '../review-dialog';

const AddReviewDialog = props =>
  <ReviewDialog
    {...props}
    buttonText={Localization.REVIEW_DIALOG.BUTTON_TEXT_POST}
    title={Localization.REVIEW_DIALOG.TITLE_ADD}
    validationText={Localization.REVIEW_DIALOG.VALIDATION_TEXT}
    imageUploadText={Localization.REVIEW_DIALOG.IMAGE_UPLOAD_TEXT}
  />;

AddReviewDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired
};

export default AddReviewDialog;
