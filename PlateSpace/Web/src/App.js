import React, { Component } from 'react';
import MuiThemeProvider from 'material-ui/styles/MuiThemeProvider';
import injectTapEventPlugin from 'react-tap-event-plugin';
import { Router, Route, hashHistory } from 'react-router';
import AuthenticationContainer from './containers/authentication-container';
import MainContainer from './containers/main-container';
import { MongoDbManager } from './mongodb-manager';
import './assets/fonts/fonts.css';
import './commons/common-styles/disabled-rate-star.css';

const enforceAuthentication = (nextState, replace) => {
  if (!MongoDbManager.isAuthenticated()) {
    replace('/');
  }
};

const redirectToMainIfAuthentication = (nextState, replace) => {
  if (MongoDbManager.isAuthenticated()) {
    replace('/restaurants');
  }
};

class App extends Component {
  constructor(props) {
    super(props);

    injectTapEventPlugin();
  }

  render() {
    return (
      <MuiThemeProvider>
        <Router history={hashHistory}>
          <Route
            path="/"
            component={AuthenticationContainer}
            onEnter={redirectToMainIfAuthentication}
          />
          <Route
            path="restaurants"
            component={MainContainer}
            onEnter={enforceAuthentication}
          />
          <Route
            path="restaurant-details/:restId"
            component={MainContainer}
            onEnter={enforceAuthentication}
          />
          <Route
            path="confirm"
            component={MainContainer}
          />
        </Router>
      </MuiThemeProvider>
    );
  }
}

export default App;
