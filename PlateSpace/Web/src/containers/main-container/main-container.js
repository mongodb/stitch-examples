import React, { Component } from 'react';
import { withRouter } from 'react-router';
import { isString } from 'lodash';
import queryString from 'query-string';

import RestaurantDetailsContainer from '../restaurant-details-container';
import RestaurantsListContainer from '../restaurants-list-container';
import ConfirmAccountContainer from '../confirm-account-container';
import { Localization } from '../../localization';
import { Colors } from '../../commons/common-styles/common-styles';
import Header from '../../components/header';
import FilterDialog from '../../components/dialogs/filter-dialog';
import { MongoDbManager } from '../../mongodb-manager';

const styles = {
  container: {
    backgroundColor: Colors.lightGrey,
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center'
  },
  map: {
    width: '618px',
    height: '507px',
    borderRadius: '10px',
    overflow: 'hidden',
    marginTop: '10px'
  }
};

const filters = [
  {
    id: 'WIFI',
    toggled: false
  },
  {
    id: 'OPEN_ON_WEEKENDS',
    toggled: false
  },
  {
    id: 'PARKING',
    toggled: false
  },
  {
    id: 'VEGETARIAN',
    toggled: false
  }
];

class MainContainer extends Component {
  constructor(props) {
    super(props);

    this.state = {
      ...this.generateState(props),
      openFilterDialog: false,
      restaurantsResult: [],
      loading: true,
      showAsList: true
    };

    this.closeDialog = this.closeDialog.bind(this);
    this.openFilterDialog = this.openFilterDialog.bind(this);
    this.saveFilters = this.saveFilters.bind(this);
    this.searchRestaurants = this.searchRestaurants.bind(this);
    this.changeView = this.changeView.bind(this);
    this.navigateToDetails = this.navigateToDetails.bind(this);
    this.logout = this.logout.bind(this);
    this.getParameterByName = this.getParameterByName.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    this.setState(this.generateState(nextProps));
  }

  generateState(props) {
    const { name = '', attributes = [] } = props.router.location.query;

    const hasAttribute = attribute => {
      if (isString(attributes)) {
        return attribute.toLowerCase() === attributes.toLowerCase();
      }
      return attributes.some(
        att => att.toLowerCase() === attribute.toLowerCase()
      );
    };

    const computedFilters = filters.map(attribute => ({
      ...attribute,
      toggled: hasAttribute(attribute.id)
    }));

    return {
      restaurantName: name,
      filters: computedFilters
    };
  }

  searchRestaurants(restaurantName) {
    const currentQuery = this.props.router.location.query;
    const query = {
      ...currentQuery,
      name: restaurantName
    };

    this.props.router.push(`/restaurants?${queryString.stringify(query)}`);
  }

  closeDialog() {
    this.setState({ openFilterDialog: false });
  }

  openFilterDialog() {
    this.setState({ openFilterDialog: true });
  }

  saveFilters(attributes) {
    const currentQuery = this.props.router.location.query;
    const query = {
      ...currentQuery,
      attributes: attributes
        .filter(attribute => attribute.toggled)
        .map(attribute => attribute.id.toLowerCase())
    };

    this.props.router.push(`/restaurants?${queryString.stringify(query)}`);
    this.setState({ openFilterDialog: false });
  }

  changeView() {
    const { showAsList } = this.state;

    this.setState({ showAsList: !showAsList });
  }

  navigateToDetails(id) {
    const currentQuery = this.props.router.location.query;
    this.props.router.push(
      `/restaurant-details/${id}?${queryString.stringify(currentQuery)}`
    );
  }

  logout() {
    MongoDbManager.logout().then(() => this.props.router.replace(`/`));
  }

 getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[[]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

  render() {
    const routerPath = this.props.router.location.pathname;
    var tokenValue = this.getParameterByName('token');
    var tokenIdValue = this.getParameterByName('tokenId');
    return (
      <div style={styles.container}>
        <Header
          title={Localization.HEADER.TITLE}
          subTitle={Localization.HEADER.SUB_TITLE}
          editButtonClicked={this.openFilterDialog}
          filters={this.state.filters}
          searchClicked={this.searchRestaurants}
          logoutClicked={this.logout}
          searchDefaultValue={this.state.restaurantName}
        />
        {routerPath === '/restaurants' && 
          <RestaurantsListContainer
              restaurantName={this.state.restaurantName}
              filters={this.state.filters}
              onRestaurantClicked={this.navigateToDetails}
              onChangeView={this.changeView}
              showAsList={this.state.showAsList}
            />
        } 
        {routerPath.startsWith('/restaurant-details') && 
          <RestaurantDetailsContainer
              restaurantId={this.props.params.restId}
            />
        } 
        {routerPath === '/confirm' && 
          <ConfirmAccountContainer 
          token={tokenValue}
          tokenId={tokenIdValue}/>
        }

        <FilterDialog
          saveFilters={this.saveFilters}
          filters={this.state.filters}
          onCancelClick={this.closeDialog}
          open={this.state.openFilterDialog}
        />
      </div>
    );
  }
}

export default withRouter(MainContainer);
