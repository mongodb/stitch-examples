import React, { Component } from 'react';

import { Colors } from '../../commons/common-styles/common-styles';
import { MongoDbManager } from '../../mongodb-manager';
import { Localization } from '../../localization';
import LoadingIndication from '../../components/loading-indication';
import RestaurantDetails from '../../components/restaurant-details';
import AddReviewDialog from '../../components/dialogs/add-review-dialog';
import EditReviewDialog from '../../components/dialogs/edit-review-dialog';
import MessageDialog from '../../components/dialogs/message-dialog';

const styles = {
  container: {
    backgroundColor: Colors.lightGrey,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    userSelect: 'none'
  },
  overlay: {
    background: 'white',
    opacity: '0.7',
    position: 'fixed',
    top: '0',
    left: '0',
    right: '0',
    bottom: '0',
    zIndex: '2',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center'
  }
};

class RestaurantDetailsContainer extends Component {
  constructor(props) {
    super(props);

    this.state = {
      loading: true,
      loadingReviews: false,
      openAddReviewDialog: false,
      openEditReviewDialog: false,
      openAddReviewDialogError: false,
      editedReview: undefined,
      details: {}
    };

    this.closeDialogs = this.closeDialogs.bind(this);
    this.openAddReviewDialog = this.openAddReviewDialog.bind(this);
    this.openEditReviewDialog = this.openEditReviewDialog.bind(this);
    this.openAddReviewDialogError = this.openAddReviewDialogError.bind(this);
    this.addReview = this.addReview.bind(this);
    this.updateReview = this.updateReview.bind(this);
    this.showAddButton = this.showAddButton.bind(this);
    this.addReviewClick = this.addReviewClick.bind(this);
    this.getUserReview = this.getUserReview.bind(this);
  }

  componentDidMount() {
    const id = this.props.restaurantId;
    if (id !== '') {
      this.fetchData(id);
    }
  }

  editableFirstThenByDate(a, b) {
    if (a.editable) {
      return -1;
    }
    if (b.editable) {
      return 1;
    }
    return b.date - a.date;
  }

  fetchData(restaurantId) {
    const restaurantDetails =
      MongoDbManager.getRestaurantDetailsById(restaurantId);
    const restaurantReviews =
      MongoDbManager.getRestaurantReviews(restaurantId);

    return Promise.all([restaurantDetails, restaurantReviews])
      .then(results => {
        const details = results[0];
        const reviews = results[1];
        if (details) {
          details.reviews = reviews.sort(this.editableFirstThenByDate) || [];
        }

        this.setState({ details, loading: false });
      })
      .catch(err => {
        console.error(err);
        this.setState({ loading: false });
      });
  }

  addReviewClick() {
    MongoDbManager.isAnonymous()
      ? this.openAddReviewDialogError()
      : this.openAddReviewDialog();
  }

  closeDialogs() {
    this.setState({
      openAddReviewDialog: false,
      openAddReviewDialogError: false,
      openEditReviewDialog: false,
      editedReview: undefined
    });
  }

  openAddReviewDialog() {
    this.setState({ openAddReviewDialog: true });
  }

  openAddReviewDialogError() {
    this.setState({ openAddReviewDialogError: true });
  }

  openEditReviewDialog(reviewId) {
    this.setState({ openEditReviewDialog: true, editedReview: reviewId });
  }

  addReview(rateValue, reviewValue, imageUrlValue, clarifaiConceptsValue) {
    const restaurantId = this.props.restaurantId;
    this.closeDialogs();
    this.setState({ loadingReviews: true });
    MongoDbManager.addReview(rateValue, reviewValue, imageUrlValue, clarifaiConceptsValue, restaurantId)
      .then(() => this.fetchData(restaurantId))
      .then(() => this.setState({ loadingReviews: false }))
      .catch(err => {
        console.error(err);
        this.setState({ loadingReviews: false });
      });
  }

  updateReview(rateValue, reviewValue, imageUrlValue, imageRecoDataValue, reviewId) {
    const restaurantId = this.props.restaurantId;
    this.closeDialogs();
    this.setState({ loadingReviews: true });
    MongoDbManager.updateReview(reviewId, rateValue, reviewValue, imageUrlValue, imageRecoDataValue, restaurantId)
      .then(() => this.fetchData(restaurantId))
      .then(() => this.setState({ loadingReviews: false }))
      .catch(err => {
        console.error(err);
        this.setState({ loadingReviews: false });
      });
  }

  showAddButton() {
    const reviews = (this.state.details && this.state.details.reviews) || [];
    return (
      MongoDbManager.isAnonymous() || reviews.every(review => !review.editable)
    );
  }

  getUserReview() {
    return (
      this.state.details &&
      this.state.details.reviews &&
      this.state.details.reviews.filter(
        review => review.id === this.state.editedReview
      )[0]
    );
  }

  render() {
    const showAddButton = this.showAddButton();
    const userReview = this.getUserReview();

    return (
      <div style={styles.container}>
        {this.state.loading && <LoadingIndication />}
        {this.state.loadingReviews &&
          <div style={styles.overlay}>
            <LoadingIndication />
          </div>}
        {!this.state.loading &&
          <RestaurantDetails
            {...this.state.details}
            style={{ marginTop: '40px' }}
            showAddReviewButton={showAddButton}
            addReviewClick={this.addReviewClick}
            editReviewClick={this.openEditReviewDialog}
          />}
        <AddReviewDialog
          open={this.state.openAddReviewDialog}
          onCancelClick={this.closeDialogs}
          onOkClick={this.addReview}
        />
        <MessageDialog
          open={this.state.openAddReviewDialogError}
          onCancelClick={this.closeDialogs}
          onOkClick={this.closeDialogs}
          title={Localization.REVIEW_DIALOG.TITLE_ADD}
          buttonText={Localization.REVIEW_DIALOG.BUTTON_TEXT_OK}
          text={Localization.REVIEW_DIALOG.ATTENTION}
        />
        {this.state.editedReview &&
          <EditReviewDialog
            rateValue={userReview.rateValue}
            reviewValue={userReview.text}
            reviewId={userReview.id}
            imageUrlValue={userReview.imageUrl}
            imageConceptsValue={userReview.imageRecognitionData}
            open={this.state.openEditReviewDialog}
            onCancelClick={this.closeDialogs}
            onOkClick={this.updateReview}
          />}
      </div>
    );
  }
}

export default RestaurantDetailsContainer;
