import React, { Component } from 'react';
import Rate from 'rc-rate';
import 'rc-rate/assets/index.css';

import { Localization } from '../../../localization';
import { Styles } from './review-dialog-style';
import StyledDialog from '../styled-dialog';

class ReviewDialog extends Component {
  constructor(props) {
    super(props);

    this.state = {
      rateValue: props.rateValue,
      reviewValue: props.reviewValue
    };

    this.saveReview = this.saveReview.bind(this);
    this.rateValueChanged = this.rateValueChanged.bind(this);
    this.inputChanged = this.inputChanged.bind(this);
  }

  inputChanged() {
    this.setState({ reviewValue: this.reviewTextInput.value });
  }

  rateValueChanged(value) {
    this.setState({ rateValue: value });
  }

  componentWillReceiveProps(nextProps) {
    this.setState({
      rateValue: nextProps.rateValue,
      reviewValue: nextProps.reviewValue
    });
  }

  saveReview() {
    if (!this.state.reviewValue && !this.state.rateValue) {
      alert(this.props.validationText);
      return;
    }
    this.props.onOkClick(
      this.state.rateValue,
      this.state.reviewValue,
      this.props.reviewId
    );
    this.setState({
      rateValue: this.props.rateValue,
      reviewValue: this.props.reviewValue
    });
  }

  render() {
    return (
      <StyledDialog
        open={this.props.open}
        title={this.props.title}
        buttonText={this.props.buttonText}
        onCancelClick={this.props.onCancelClick}
        onOkClick={this.saveReview}
        content={
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center'
            }}
          >
            <textarea
              maxLength={140}
              ref={reviewTextInput => (this.reviewTextInput = reviewTextInput)}
              onBlur={this.inputChanged}
              style={Styles.input}
              placeholder={Localization.REVIEW_DIALOG.INPUT_PLACEHOLDER}
              defaultValue={this.state.reviewValue}
            />
            <div style={Styles.rateTitle}>
              {Localization.REVIEW_DIALOG.RATE_TITLE}
            </div>
            <Rate
              defaultValue={this.state.rateValue}
              onChange={this.rateValueChanged}
              style={{ fontSize: 55 }}
            />
          </div>
        }
      />
    );
  }
}

ReviewDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  title: React.PropTypes.string,
  buttonText: React.PropTypes.string,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired,
  rateValue: React.PropTypes.number,
  reviewValue: React.PropTypes.string,
  validationText: React.PropTypes.string.isRequired
};

ReviewDialog.defaultProps = {
  buttonText: 'OK',
  title: 'REVIEW DIALOG TITLE',
  rateValue: 0,
  reviewValue: ''
};

export default ReviewDialog;
