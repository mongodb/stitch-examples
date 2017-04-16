/* global window, fetch */

import { createStorage } from './storage';
import { BaasError } from './errors';
import * as common from './common';
import {
  btoa as b64Encode,
  atob as b64Decode
} from 'Base64';

export default class Auth {
  constructor(rootUrl) {
    this.rootUrl = rootUrl;
    this.authDataStorage = createStorage('localStorage');
  }

  pageRootUrl() {
    return [window.location.protocol, '//', window.location.host, window.location.pathname].join('');
  }

  // The state we generate is to be used for any kind of request where we will
  // complete an authentication flow via a redirect. We store the generate in
  // a local storage bound to the app's origin. This ensures that any time we
  // receive a redirect, there must be a state parameter and it must match
  // what we ourselves have generated. This state MUST only be sent to
  // a trusted BaaS endpoint in order to preserve its integrity. BaaS will
  // store it in some way on its origin (currently a cookie stored on this client)
  // and use that state at the end of an auth flow as a parameter in the redirect URI.
  static generateState() {
    let alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let state = '';
    const stateLength = 64;
    for (let i = 0; i < stateLength; i++) {
      let pos = Math.floor(Math.random() * alpha.length);
      state += alpha.substring(pos, pos + 1);
    }

    return state;
  }

  setAccessToken(token) {
    let currAuth = this.get();
    currAuth.accessToken = token;
    currAuth.refreshToken = this.authDataStorage.get(common.REFRESH_TOKEN_KEY);
    this.set(currAuth);
  }

  error() {
    return this._error;
  }

  handleRedirect() {
    if (typeof (window) === 'undefined') {
      // This means we're running in some environment other
      // than a browser - so handling a redirect makes no sense here.
      return;
    }

    let ourState = this.authDataStorage.get(common.STATE_KEY);
    let redirectFragment = window.location.hash.substring(1);
    const redirectState = common.parseRedirectFragment(redirectFragment, ourState);
    if (redirectState.lastError) {
      console.error(`BaasClient: error from redirect: ${redirectState.lastError}`);
      this._error = redirectState.lastError;
      window.history.replaceState(null, '', this.pageRootUrl());
      return;
    }

    if (!redirectState.found) {
      return;
    }

    this.authDataStorage.remove(common.STATE_KEY);
    if (!redirectState.stateValid) {
      console.error('BaasClient: state values did not match!');
      window.history.replaceState(null, '', this.pageRootUrl());
      return;
    }

    if (!redirectState.ua) {
      console.error('BaasClient: no UA value was returned from redirect!');
      return;
    }

    // If we get here, the state is valid - set auth appropriately.
    this.set(redirectState.ua);
    window.history.replaceState(null, '', this.pageRootUrl());
  }

  getOAuthLoginURL(providerName, redirectUrl) {
    if (redirectUrl === undefined) {
      redirectUrl = this.pageRootUrl();
    }

    let state = Auth.generateState();
    this.authDataStorage.set(common.STATE_KEY, state);
    let result = `${this.rootUrl}/oauth2/${providerName}?redirect=${encodeURI(redirectUrl)}&state=${state}`;
    return result;
  }

  anonymousAuth() {
    let fetchArgs = common.makeFetchArgs('GET');
    fetchArgs.cors = true;

    return fetch(`${this.rootUrl}/anon/user`, fetchArgs)
      .then(common.checkStatus)
      .then(response => response.json())
      .then(json => this.set(json));
  }

  apiKeyAuth(key) {
    const fetchArgs = common.makeFetchArgs('POST', JSON.stringify({'key': key}));
    fetchArgs.cors = true;

    return fetch(`${this.rootUrl}/api/key`, fetchArgs)
      .then(common.checkStatus)
      .then(response => response.json())
      .then(json => this.set(json));
  }

  localAuth(username, password, options = {cors: true}) {
    const fetchArgs = common.makeFetchArgs('POST', JSON.stringify({username, password}));
    fetchArgs.cors = true;

    return fetch(`${this.rootUrl}/local/userpass`, fetchArgs)
      .then(common.checkStatus)
      .then(response => response.json())
      .then(json => {
        this.set(json);
        return json;
      });
  }

  clear() {
    this.authDataStorage.remove(common.USER_AUTH_KEY);
    this.authDataStorage.remove(common.REFRESH_TOKEN_KEY);
    this.clearImpersonation();
  }

  getRefreshToken() {
    return this.authDataStorage.get(common.REFRESH_TOKEN_KEY);
  }

  set(json) {
    let rt = json.refreshToken;
    delete json.refreshToken;

    this.authDataStorage.set(common.USER_AUTH_KEY, b64Encode(JSON.stringify(json)));
    this.authDataStorage.set(common.REFRESH_TOKEN_KEY, rt);
  }

  get() {
    if (!this.authDataStorage.get(common.USER_AUTH_KEY)) {
      return null;
    }

    const item = this.authDataStorage.get(common.USER_AUTH_KEY);
    return JSON.parse(b64Decode(item));
  }

  authedId() {
    let id = ((this.get() || {}).user || {})._id;
    if (id) {
      return {'$oid': id};
    }
  }

  isImpersonatingUser() {
    return this.authDataStorage.get(common.IMPERSONATION_ACTIVE_KEY) === 'true';
  }

  refreshImpersonation(client) {
    let userId = this.authDataStorage.get(common.IMPERSONATION_USER_KEY);
    return client._do(`/admin/users/${userId}/impersonate`, 'POST', { refreshOnFailure: false, useRefreshToken: true })
      .then(response => response.json())
      .then(json => {
        json.refreshToken = this.authDataStorage.get(common.REFRESH_TOKEN_KEY);
        this.set(json);
      })
      .catch(e => {
        this.stopImpersonation();
        throw e;  // rethrow
      });
  }

  startImpersonation(client, userId) {
    if (this.get() === null) {
      return Promise.reject(new BaasError('Must auth first'));
    }

    if (this.isImpersonatingUser()) {
      return Promise.reject(new BaasError('Already impersonating a user'));
    }

    this.authDataStorage.set(common.IMPERSONATION_ACTIVE_KEY, 'true');
    this.authDataStorage.set(common.IMPERSONATION_USER_KEY, userId);

    let realUserAuth = JSON.parse(b64Decode(this.authDataStorage.get(common.USER_AUTH_KEY)));
    realUserAuth.refreshToken = this.authDataStorage.get(common.REFRESH_TOKEN_KEY);
    this.authDataStorage.set(common.IMPERSONATION_REAL_USER_AUTH_KEY, b64Encode(JSON.stringify(realUserAuth)));
    return this.refreshImpersonation(client);
  }

  stopImpersonation() {
    if (!this.isImpersonatingUser()) {
      throw new BaasError('Not impersonating a user');
    }

    return new Promise((resolve, reject) => {
      let realUserAuth = JSON.parse(b64Decode(this.authDataStorage.get(common.IMPERSONATION_REAL_USER_AUTH_KEY)));
      this.set(realUserAuth);
      this.clearImpersonation();
      resolve();
    });
  }

  clearImpersonation() {
    this.authDataStorage.remove(common.IMPERSONATION_ACTIVE_KEY);
    this.authDataStorage.remove(common.IMPERSONATION_USER_KEY);
    this.authDataStorage.remove(common.IMPERSONATION_REAL_USER_AUTH_KEY);
  }
}

