import React from 'react';

import { Localization } from '../../../localization';
import ReviewDialog from '../review-dialog';

const EditReviewDialog = props =>
  <ReviewDialog
    {...props}
    buttonText={Localization.REVIEW_DIALOG.BUTTON_TEXT_POST}
    title={Localization.REVIEW_DIALOG.TITLE_EDIT}
    validationText={Localization.REVIEW_DIALOG.VALIDATION_TEXT}
    imageUploadText={Localization.REVIEW_DIALOG.IMAGE_UPLOAD_TEXT}
  />;

EditReviewDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired,
  rateValue: React.PropTypes.number,
  reviewValue: React.PropTypes.string,
  imageUrlValue: React.PropTypes.string,
  imageRecoginationDataValue: React.PropTypes.string,
  reviewId: React.PropTypes.string
};

export default EditReviewDialog;
