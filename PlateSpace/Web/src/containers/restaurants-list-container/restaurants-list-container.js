import React, { PureComponent } from 'react';
import { withRouter } from 'react-router';
import { isEqual } from 'lodash';

import { Colors } from '../../commons/common-styles/common-styles';
import { MongoDbManager } from '../../mongodb-manager';
import NoResultsLabel from '../../components/no-results-label';
import LoadingIndication from '../../components/loading-indication';
import MapWithResults from './map-with-results';
import ListWithResults from './list-with-results';

const styles = {
  container: {
    backgroundColor: Colors.lightGrey,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center'
  }
};

const ContentList = props =>
  props.restaurants.length > 0
    ? <ListWithResults {...props} />
    : <NoResultsLabel />;

const ContentMap = props =>
  props.restaurants.length > 0
    ? <MapWithResults {...props} />
    : <NoResultsLabel />;

class RestaurantsListContainer extends PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      openFilterDialog: false,
      restaurantsResult: [],
      loading: false,
      showAsList: true
    };

    this.dataStatus = {
      isRequesting: false
    };

    this.closeDialog = this.closeDialog.bind(this);
    this.openFilterDialog = this.openFilterDialog.bind(this);
    this.fetchMoreData = this.fetchMoreData.bind(this);
    this.searchRestaurants = this.searchRestaurants.bind(this);
    this.getAllRestaurants = this.getAllRestaurants.bind(this);
  }

  componentDidMount() {
    const { restaurantName, filters } = this.props;
    if (restaurantName || filters) {
      this.searchRestaurants(restaurantName, filters);
    } else {
      this.getAllRestaurants();
    }
  }

  componentWillReceiveProps(nextProps) {
    if (
      !isEqual(nextProps.filters, this.props.filters) ||
      !isEqual(nextProps.restaurantName, this.props.restaurantName)
    ) {
      this.searchRestaurants(nextProps.restaurantName, nextProps.filters);
    }
  }

  searchRestaurants(toSearch, filters) {
    this.setState({ loading: true });
    MongoDbManager.getFilteredRestaurants(toSearch, filters).then(result => {
      this.setState({ restaurantsResult: result, loading: false });
    });
  }

  getAllRestaurants() {
    this.setState({ loading: true });
    MongoDbManager.getRestaurants().then(result => {
      this.setState({ restaurantsResult: result, loading: false });
    });
  }

  closeDialog() {
    this.setState({ openFilterDialog: false });
  }

  openFilterDialog() {
    this.setState({ openFilterDialog: true });
  }

  fetchMoreData() {
    if (this.dataStatus.isRequesting) {
      return;
    }

    this.dataStatus.isRequesting = true;

    const { restaurantsResult } = this.state;
    const lastResult = restaurantsResult[restaurantsResult.length - 1];
    const minimumDistance = lastResult.distanceRaw;
    const resultsWithSameDistance = restaurantsResult.filter(
      restaurant => restaurant.distanceRaw === minimumDistance
    );

    MongoDbManager.findRestaurantsByGeoNear(
      this.props.restaurantName,
      this.props.filters,
      minimumDistance,
      resultsWithSameDistance
    )
      .then(result => {
        this.dataStatus.isRequesting = false;
        this.setState({
          restaurantsResult: [...this.state.restaurantsResult, ...result]
        });
      })
      .catch(error => {
        this.dataStatus.isRequesting = false;
      });
  }

  render() {
    return (
      <div style={styles.container}>
        {!this.state.loading &&
          this.props.showAsList &&
          <ContentList
            onItemClicked={this.props.onRestaurantClicked}
            buttonHeaderClick={this.props.onChangeView}
            fetchFunc={this.fetchMoreData}
            restaurants={this.state.restaurantsResult}
          />}
        {!this.state.loading &&
          !this.props.showAsList &&
          <ContentMap
            onItemClicked={this.props.onRestaurantClicked}
            buttonHeaderClick={this.props.onChangeView}
            restaurants={this.state.restaurantsResult}
          />}
        {this.state.loading && <LoadingIndication />}
      </div>
    );
  }
}

export default withRouter(RestaurantsListContainer);
