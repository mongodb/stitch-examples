import React, { Component } from 'react';
import { storiesOf, action, linkTo } from '@kadira/storybook';
import StyledDialog from './styled-dialog';
import FilterDialog from './filter-dialog';
import MessageDialog from './message-dialog';
import AddReviewDialog from './add-review-dialog';
import EditReviewDialog from './edit-review-dialog';
import { mocks } from '../../storybook-mocks';
import { Localization } from '../../localization';

storiesOf('Dialogs', module)
  .add('Filter dialog', () =>
    <FilterDialog
      saveFilters={action('save clicked')}
      filters={mocks.filters}
      onCancelClick={action('cancel clicked')}
      saveFilters={action('save clicked')}
      open={true}
    />
  )
  .add('Message dialog', () =>
    <MessageDialog
      title={Localization.REVIEW_DIALOG.TITLE_ADD}
      open={true}
      buttonText={Localization.REVIEW_DIALOG.BUTTON_TEXT_POST}
      onCancelClick={action('cancel clicked')}
      onOkClick={action('post clicked')}
      text={Localization.REVIEW_DIALOG.ATTENTION}
    />
  )
  .add('Add review dialog', () =>
    <AddReviewDialog
      open={true}
      onCancelClick={action('cancel clicked')}
      onOkClick={action('post clicked')}
    />
  )
  .add('Edit review dialog', () =>
    <EditReviewDialog
      rateValue={4}
      reviewValue={
        'My boyfriend called to make a reservation but was told it was by walk ins only. When we arrived, there was a line already forming.'
      }
      open={true}
      onCancelClick={action('cancel clicked')}
      onOkClick={action('post clicked')}
    />
  );
