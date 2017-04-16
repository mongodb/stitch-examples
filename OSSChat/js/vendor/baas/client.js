/* global window, fetch */
/* eslint no-labels: ['error', { 'allowLoop': true }] */
require('es6-promise').polyfill();
require('fetch-everywhere');
import Auth from './auth';
import MongoDBService from './services/mongodb/mongodb_service';
import { BaasError } from './errors';
import * as common from './common';
import { TextDecoder } from 'text-encoding-utf-8';
import ExtJSONModule from 'mongodb-extjson';
const EJSON = new ExtJSONModule();
const UTF8Decoder = new TextDecoder('utf-8');

const ErrAuthProviderNotFound = 'AuthProviderNotFound';
const ErrInvalidSession = 'InvalidSession';
const ErrUnauthorized = 'Unauthorized';

const toQueryString = (obj) => {
  let parts = [];
  for (let i in obj) {
    if (obj.hasOwnProperty(i)) {
      parts.push(encodeURIComponent(i) + '=' + encodeURIComponent(obj[i]));
    }
  }
  return parts.join('&');
};


/**
 * Create a new BaasClient instance.
 *
 * @class
 * @return {BaasClient} a BaasClient instance.
 */
class BaasClient {
  constructor(clientAppID, options) {
    let baseUrl = common.DEFAULT_BAAS_SERVER_URL;
    if (options && options.baseUrl) {
      baseUrl = options.baseUrl;
    }
    this.appUrl = `${baseUrl}/admin/v1`;
    this.authUrl = `${baseUrl}/admin/v1/auth`;
    if (clientAppID) {
      this.appUrl = `${baseUrl}/v1/app/${clientAppID}`;
      this.authUrl = `${this.appUrl}/auth`;
    }
    this.authManager = new Auth(this.authUrl);
    this.authManager.handleRedirect();
  }

  /**
   * Sends the user to the OAuth flow for the specified third-party service.
   *
   * @param {*} providerName The OAuth provider name.
   * @param {*} redirectUrl The redirect URL to use after the flow completes.
   */
  authWithOAuth(providerName, redirectUrl) {
    window.location.replace(this.authManager.getOAuthLoginURL(providerName, redirectUrl));
  }

  /**
   * Generates a URL that can be used to initiate an OAuth login flow with the specified OAuth provider.
   *
   * @param {*} providerName The OAuth provider name.
   * @param {*} redirectUrlThe redirect URL to use after the flow completes.
   */
  getOAuthLoginURL(providerName, redirectUrl) {
    return this.authManager.getOAuthLoginURL(providerName, redirectUrl);
  }

  /**
   * Logs in as an anonymous user.
   */
  anonymousAuth() {
    return this.authManager.anonymousAuth();
  }

  /**
   *  @return {ObjectID} Returns the currently authed user's ID.
   */
  authedId() {
    return this.authManager.authedId();
  }

  /**
   * @return {Object} Returns the currently authed user's authentication information.
   */
  auth() {
    return this.authManager.get();
  }

  /**
   * @return {*} Returns any error from the BaaS authentication system.
   */
  authError() {
    return this.authManager.error();
  }

  /**
   * Ends the session for the current user.
   */
  logout() {
    return this._do('/auth', 'DELETE', {refreshOnFailure: false, useRefreshToken: true})
      .then(() => this.authManager.clear());
  }

  /**
   * Factory method for accessing BaaS services.
   *
   * @method
   * @param {String} type The service type [mongodb, {String}]
   * @param {String} name The service name.
   * @return {Object} returns a named service.
   */
  service(type, name) {
    if (this.constructor !== BaasClient) {
      throw new BaasError('`service` is a factory method, do not use `new`');
    }

    if (type === 'mongodb') {
      return new MongoDBService(this, name);
    }

    throw new BaasError('Invalid service type specified: ' + type);
  }

  /**
   * Executes a service pipeline.
   *
   * @param {Array} stages Stages to process.
   * @param {Object} [options] Additional options to pass to the execution context.
   */
  executePipeline(stages, options = {}) {
    let responseDecoder = (d) => EJSON.parse(d, { strict: false });
    let responseEncoder = (d) => EJSON.stringify(d);

    if (options.decoder) {
      if ((typeof options.decoder) !== 'function') {
        throw new Error('decoder option must be a function, but "' + typeof (options.decoder) + '" was provided');
      }
      responseDecoder = options.decoder;
    }

    if (options.encoder) {
      if ((typeof options.encoder) !== 'function') {
        throw new Error('encoder option must be a function, but "' + typeof (options.encoder) + '" was provided');
      }
      responseEncoder = options.encoder;
    }

    return this._do('/pipeline', 'POST', { body: responseEncoder(stages) })
      .then(response => (response.arrayBuffer) ? response.arrayBuffer() : response.buffer())
      .then(buf => UTF8Decoder.decode(buf))
      .then(body => responseDecoder(body));
  }

  _do(resource, method, options) {
    options = Object.assign({}, {
      refreshOnFailure: true,
      useRefreshToken: false
    }, options);

    if (!options.noAuth) {
      if (this.auth() === null) {
        return Promise.reject(new BaasError('Must auth first', ErrUnauthorized));
      }
    }

    let url = `${this.appUrl}${resource}`;
    let fetchArgs = common.makeFetchArgs(method, options.body);

    if (!!options.headers) {
      Object.assign(fetchArgs.headers, options.headers);
    }

    if (!options.noAuth) {
      let token = options.useRefreshToken ? this.authManager.getRefreshToken() : this.auth().accessToken;
      fetchArgs.headers.Authorization = `Bearer ${token}`;
    }

    if (options.queryParams) {
      url = url + '?' + toQueryString(options.queryParams);
    }

    return fetch(url, fetchArgs).then((response) => {
      // Okay: passthrough
      if (response.status >= 200 && response.status < 300) {
        return Promise.resolve(response);
      }

      if (response.headers.get('Content-Type') === common.JSONTYPE) {
        return response.json().then((json) => {
          // Only want to try refreshing token when there's an invalid session
          if ('errorCode' in json && json.errorCode === ErrInvalidSession) {
            if (!options.refreshOnFailure) {
              this.authManager.clear();
              const error = new BaasError(json.error, json.errorCode);
              error.response = response;
              throw error;
            }

            return this._refreshToken().then(() => {
              options.refreshOnFailure = false;
              return this._do(resource, method, options);
            });
          }

          const error = new BaasError(json.error, json.errorCode);
          error.response = response;
          return Promise.reject(error);
        });
      }

      const error = new Error(response.statusText);
      error.response = response;

      return Promise.reject(error);
    });
  }

  _refreshToken() {
    if (this.authManager.isImpersonatingUser()) {
      return this.authManager.refreshImpersonation(this);
    }

    return this._do('/auth/newAccessToken', 'POST', { refreshOnFailure: false, useRefreshToken: true })
      .then(response => response.json())
      .then(json => this.authManager.setAccessToken(json.accessToken));
  }
}

class Admin {
  constructor(baseUrl) {
    this.client = new BaasClient('', {baseUrl});
  }

  _do(url, method, options) {
    return this.client._do(url, method, options)
      .then(response => response.json());
  }

  _get(url, queryParams) {
    return this._do(url, 'GET', {queryParams});
  }

  _put(url, options) {
    return this._do(url, 'PUT', options);
  }

  _delete(url) {
    return this._do(url, 'DELETE');
  }

  _post(url, body) {
    return this._do(url, 'POST', {body: JSON.stringify(body)});
  }

  profile() {
    let root = this;
    return {
      keys: () => ({
        list: () => root._get('/profile/keys'),
        create: (key) => root._post('/profile/keys'),
        apiKey: (keyId) => ({
          get: () => root._get(`/profile/keys/${keyId}`),
          remove: () => this._delete(`/profile/keys/${keyId}`),
          enable: () => root._put(`/profile/keys/${keyId}/enable`),
          disable: () => root._put(`/profile/keys/${keyId}/disable`)
        })
      })
    };
  }

  /* Examples of how to access admin API with this client:
   *
   * List all apps
   *    a.apps().list()
   *
   * Fetch app under name 'planner'
   *    a.apps().app('planner').get()
   *
   * List services under the app 'planner'
   *    a.apps().app('planner').services().list()
   *
   * Delete a rule by ID
   *    a.apps().app('planner').services().service('mdb1').rules().rule('580e6d055b199c221fcb821d').remove()
   *
   */
  apps() {
    let root = this;
    return {
      list: () => root._get('/apps'),
      create: (data, options) => {
        let query = (options && options.defaults) ? '?defaults=true' : '';
        return root._post('/apps' + query, data);
      },

      app: (appID) => ({
        get: () => root._get(`/apps/${appID}`),
        remove: () => root._delete(`/apps/${appID}`),
        replace: (doc) => root._put(`/apps/${appID}`, {
          headers: { 'X-Baas-Unsafe': appID },
          body: JSON.stringify(doc)
        }),

        users: () => ({
          list: (filter) => this._get(`/apps/${appID}/users`, filter),
          user: (uid) => ({
            get: () => this._get(`/apps/${appID}/users/${uid}`),
            logout: () => this._put(`/apps/${appID}/users/${uid}/logout`)
          })
        }),

        sandbox: () => ({
          executePipeline: (data, userId) => {
            return this._do(
              `/apps/${appID}/sandbox/pipeline`,
              'POST',
              {body: JSON.stringify(data), queryParams: {user_id: userId}});
          }
        }),

        authProviders: () => ({
          create: (data) => this._post(`/apps/${appID}/authProviders`, data),
          list: () => this._get(`/apps/${appID}/authProviders`),
          provider: (authType, authName) => ({
            get: () => this._get(`/apps/${appID}/authProviders/${authType}/${authName}`),
            remove: () => this._delete(`/apps/${appID}/authProviders/${authType}/${authName}`),
            update: (data) => this._post(`/apps/${appID}/authProviders/${authType}/${authName}`, data)
          })
        }),
        values: () => ({
          list: () => this._get(`/apps/${appID}/values`),
          value: (varName) => ({
            get: () => this._get(`/apps/${appID}/values/${varName}`),
            remove: () => this._delete(`/apps/${appID}/values/${varName}`),
            create: (data) => this._post(`/apps/${appID}/values/${varName}`, data),
            update: (data) => this._post(`/apps/${appID}/values/${varName}`, data)
          })
        }),
        pipelines: () => ({
          list: () => this._get(`/apps/${appID}/pipelines`),
          pipeline: (varName) => ({
            get: () => this._get(`/apps/${appID}/pipelines/${varName}`),
            remove: () => this._delete(`/apps/${appID}/pipelines/${varName}`),
            create: (data) => this._post(`/apps/${appID}/pipelines/${varName}`, data),
            update: (data) => this._post(`/apps/${appID}/pipelines/${varName}`, data)
          })
        }),
        logs: () => ({
          get: (filter) => this._get(`/apps/${appID}/logs`, filter)
        }),
        apiKeys: () => ({
          list: () => this._get(`/apps/${appID}/keys`),
          create: (data) => this._post(`/apps/${appID}/keys`, data),
          apiKey: (key) => ({
            get: () => this._get(`/apps/${appID}/keys/${key}`),
            remove: () => this._delete(`/apps/${appID}/keys/${key}`),
            enable: () => this._put(`/apps/${appID}/keys/${key}/enable`),
            disable: () => this._put(`/apps/${appID}/keys/${key}/disable`)
          })
        }),
        services: () => ({
          list: () => this._get(`/apps/${appID}/services`),
          create: (data) => this._post(`/apps/${appID}/services`, data),
          service: (svc) => ({
            get: () => this._get(`/apps/${appID}/services/${svc}`),
            update: (data) => this._post(`/apps/${appID}/services/${svc}`, data),
            remove: () => this._delete(`/apps/${appID}/services/${svc}`),
            setConfig: (data) => this._post(`/apps/${appID}/services/${svc}/config`, data),

            rules: () => ({
              list: () => this._get(`/apps/${appID}/services/${svc}/rules`),
              create: (data) => this._post(`/apps/${appID}/services/${svc}/rules`),
              rule: (ruleId) => ({
                get: () => this._get(`/apps/${appID}/services/${svc}/rules/${ruleId}`),
                update: (data) => this._post(`/apps/${appID}/services/${svc}/rules/${ruleId}`, data),
                remove: () => this._delete(`/apps/${appID}/services/${svc}/rules/${ruleId}`)
              })
            }),

            incomingWebhooks: () => ({
              list: () => this._get(`/apps/${appID}/services/${svc}/incomingWebhooks`),
              create: (data) => this._post(`/apps/${appID}/services/${svc}/incomingWebhooks`),
              incomingWebhook: (incomingWebhookId) => ({
                get: () => this._get(`/apps/${appID}/services/${svc}/incomingWebhooks/${incomingWebhookId}`),
                update: (data) => this._post(`/apps/${appID}/services/${svc}/incomingWebhooks/${incomingWebhookId}`, data),
                remove: () => this._delete(`/apps/${appID}/services/${svc}/incomingWebhooks/${incomingWebhookId}`)
              })
            })
          })
        })
      })
    };
  }

  _admin() {
    return {
      logs: () => ({
        get: (filter) => this._do('/admin/logs', 'GET', {useRefreshToken: true, queryParams: filter})
      }),
      users: () => ({
        list: (filter) => this._do('/admin/users', 'GET', {useRefreshToken: true, queryParams: filter}),
        user: (uid) => ({
          logout: () => this._do(`/admin/users/${uid}/logout`, 'PUT', {useRefreshToken: true})
        })
      })
    };
  }

  _isImpersonatingUser() {
    return this.client.authManager.isImpersonatingUser();
  }

  _startImpersonation(userId) {
    return this.client.authManager.startImpersonation(this.client, userId);
  }

  _stopImpersonation() {
    return this.client.authManager.stopImpersonation();
  }
}

export {
  BaasClient,
  Admin,
  ErrAuthProviderNotFound,
  ErrInvalidSession,
  ErrUnauthorized,
  toQueryString
};
