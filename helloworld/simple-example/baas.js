var Baas =
/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;
/******/
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	'use strict';
	
	Object.defineProperty(exports, "__esModule", {
	  value: true
	});
	exports.Admin = exports.MongoClient = exports.BaasClient = exports.Auth = exports.BaasError = exports.parseRedirectFragment = exports.ErrInvalidSession = exports.ErrAuthProviderNotFound = undefined;
	
	var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();
	
	__webpack_require__(1);
	
	function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
	
	function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }
	
	function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; } /* global window, localStorage, fetch */
	/* eslint no-labels: ["error", { "allowLoop": true }] */
	
	
	// fetch polyfill
	
	var USER_AUTH_KEY = '_baas_ua';
	var REFRESH_TOKEN_KEY = '_baas_rt';
	var STATE_KEY = '_baas_state';
	var BAAS_ERROR_KEY = '_baas_error';
	var BAAS_LINK_KEY = '_baas_link';
	var DEFAULT_BAAS_SERVER_URL = 'https://baas-dev.10gen.cc/';
	
	var ErrAuthProviderNotFound = exports.ErrAuthProviderNotFound = 'AuthProviderNotFound';
	var ErrInvalidSession = exports.ErrInvalidSession = 'InvalidSession';
	var stateLength = 64;
	
	var toQueryString = function toQueryString(obj) {
	  var parts = [];
	  for (var i in obj) {
	    if (obj.hasOwnProperty(i)) {
	      parts.push(encodeURIComponent(i) + '=' + encodeURIComponent(obj[i]));
	    }
	  }
	  return parts.join('&');
	};
	
	var checkStatus = function checkStatus(response) {
	  if (response.status >= 200 && response.status < 300) {
	    return response;
	  } else {
	    var error = new Error(response.statusText);
	    error.response = response;
	    throw error;
	  }
	};
	
	var parseRedirectFragment = exports.parseRedirectFragment = function parseRedirectFragment(fragment, ourState) {
	  // After being redirected from oauth, the URL will look like:
	  // https://todo.examples.baas-dev.10gen.cc/#_baas_state=...&_baas_ua=...
	  // This function parses out baas-specific tokens from the fragment and
	  // builds an object describing the result.
	  var vars = fragment.split('&');
	  var result = { ua: null, found: false, stateValid: false, lastError: null };
	  var _iteratorNormalCompletion = true;
	  var _didIteratorError = false;
	  var _iteratorError = undefined;
	
	  try {
	    outerloop: for (var _iterator = vars[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
	      var pair = _step.value;
	
	      var pairParts = pair.split('=');
	      var pairKey = decodeURIComponent(pairParts[0]);
	      switch (pairKey) {
	        case BAAS_ERROR_KEY:
	          result.lastError = decodeURIComponent(pairParts[1]);
	          result.found = true;
	          break outerloop;
	        case USER_AUTH_KEY:
	          result.ua = JSON.parse(window.atob(decodeURIComponent(pairParts[1])));
	          result.found = true;
	          continue;
	        case BAAS_LINK_KEY:
	          result.found = true;
	          continue;
	        case STATE_KEY:
	          result.found = true;
	          var theirState = decodeURIComponent(pairParts[1]);
	          if (ourState && ourState === theirState) {
	            result.stateValid = true;
	          }
	      }
	    }
	  } catch (err) {
	    _didIteratorError = true;
	    _iteratorError = err;
	  } finally {
	    try {
	      if (!_iteratorNormalCompletion && _iterator.return) {
	        _iterator.return();
	      }
	    } finally {
	      if (_didIteratorError) {
	        throw _iteratorError;
	      }
	    }
	  }
	
	  return result;
	};
	
	var BaasError = exports.BaasError = function (_Error) {
	  _inherits(BaasError, _Error);
	
	  function BaasError(message, code) {
	    _classCallCheck(this, BaasError);
	
	    var _this = _possibleConstructorReturn(this, (BaasError.__proto__ || Object.getPrototypeOf(BaasError)).call(this, message));
	
	    _this.name = 'BaasError';
	    _this.message = message;
	    if (code !== undefined) {
	      _this.code = code;
	    }
	    if (typeof Error.captureStackTrace === 'function') {
	      Error.captureStackTrace(_this, _this.constructor);
	    } else {
	      _this.stack = new Error(message).stack;
	    }
	    return _this;
	  }
	
	  return BaasError;
	}(Error);
	
	var Auth = exports.Auth = function () {
	  function Auth(rootUrl) {
	    _classCallCheck(this, Auth);
	
	    this.rootUrl = rootUrl;
	  }
	
	  _createClass(Auth, [{
	    key: 'pageRootUrl',
	    value: function pageRootUrl() {
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
	
	  }, {
	    key: 'setAccessToken',
	    value: function setAccessToken(token) {
	      var currAuth = this.get();
	      currAuth['accessToken'] = token;
	      this.set(currAuth);
	    }
	  }, {
	    key: 'handleRedirect',
	    value: function handleRedirect() {
	      var ourState = localStorage.getItem(STATE_KEY);
	      var redirectFragment = window.location.hash.substring(1);
	      console.log("handling Redirect with ourstate", ourState, "redirect fragement is", redirectFragment);
	      var redirectState = parseRedirectFragment(redirectFragment, ourState);
	      console.log("parsed redirect state is", redirectState);
	      if (redirectState.lastError) {
	        console.error('BaasClient: error from redirect: ' + redirectState.lastError);
	        window.history.replaceState(null, '', this.pageRootUrl());
	        return;
	      }
	      if (!redirectState.found) {
	        return;
	      }
	      localStorage.removeItem(STATE_KEY);
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
	  }, {
	    key: 'getOAuthLoginURL',
	    value: function getOAuthLoginURL(providerName, redirectUrl) {
	      if (redirectUrl === undefined) {
	        redirectUrl = this.pageRootUrl();
	      }
	      var state = Auth.generateState();
	      localStorage.setItem(STATE_KEY, state);
	      console.log("doing oauth with", providerName, "redirect to", redirectUrl, "state set to", state);
	      var result = this.rootUrl + '/oauth2/' + providerName + '?redirect=' + encodeURI(redirectUrl) + '&state=' + state;
	      return result;
	    }
	  }, {
	    key: 'localAuth',
	    value: function localAuth(username, password, cors) {
	      var _this2 = this;
	
	      var init = {
	        method: 'POST',
	        headers: {
	          'Accept': 'application/json',
	          'Content-Type': 'application/json'
	        },
	        body: JSON.stringify({ 'username': username, 'password': password })
	      };
	
	      if (cors) {
	        init['cors'] = cors;
	      }
	
	      return fetch(this.rootUrl + '/local/userpass', init).then(checkStatus).then(function (response) {
	        return response.json().then(function (json) {
	          _this2.set(json);
	          Promise.resolve();
	        });
	      });
	    }
	  }, {
	    key: 'clear',
	    value: function clear() {
	      localStorage.removeItem(USER_AUTH_KEY);
	      localStorage.removeItem(REFRESH_TOKEN_KEY);
	    }
	  }, {
	    key: 'set',
	    value: function set(json) {
	      var rt = json['refreshToken'];
	      delete json['refreshToken'];
	
	      localStorage.setItem(USER_AUTH_KEY, window.btoa(JSON.stringify(json)));
	      localStorage.setItem(REFRESH_TOKEN_KEY, rt);
	    }
	  }, {
	    key: 'get',
	    value: function get() {
	      if (localStorage.getItem(USER_AUTH_KEY) === null) {
	        return null;
	      }
	      return JSON.parse(window.atob(localStorage.getItem(USER_AUTH_KEY)));
	    }
	  }, {
	    key: 'authedId',
	    value: function authedId() {
	      var a = this.get();
	      return ((a || {}).user || {})._id;
	    }
	  }], [{
	    key: 'generateState',
	    value: function generateState() {
	      var alpha = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
	      var state = '';
	      for (var i = 0; i < stateLength; i++) {
	        var pos = Math.floor(Math.random() * alpha.length);
	        state += alpha.substring(pos, pos + 1);
	      }
	      return state;
	    }
	  }]);
	
	  return Auth;
	}();
	
	var BaasClient = exports.BaasClient = function () {
	  function BaasClient(app, options) {
	    _classCallCheck(this, BaasClient);
	
	    var baseUrl = DEFAULT_BAAS_SERVER_URL;
	    if (options && options.baseUrl) {
	      baseUrl = options.baseUrl;
	    }
	    this.appUrl = baseUrl + '/admin/v1';
	    this.authUrl = baseUrl + '/admin/v1/auth';
	    if (app) {
	      this.appUrl = baseUrl + '/v1/app/' + app;
	      this.authUrl = this.appUrl + '/auth';
	    }
	    this.authManager = new Auth(this.authUrl);
	    this.authManager.handleRedirect();
	  }
	
	  _createClass(BaasClient, [{
	    key: 'authWithOAuth',
	    value: function authWithOAuth(providerName, redirectUrl) {
	      window.location.replace(this.authManager.getOAuthLoginURL(providerName, redirectUrl));
	    }
	  }, {
	    key: 'authedId',
	    value: function authedId() {
	      return this.authManager.authedId();
	    }
	  }, {
	    key: 'auth',
	    value: function auth() {
	      return this.authManager.get();
	    }
	  }, {
	    key: 'logout',
	    value: function logout() {
	      var _this3 = this;
	
	      return this._doAuthed('/auth', 'DELETE', { refreshOnFailure: false, useRefreshToken: true }).then(function (data) {
	        _this3.authManager.clear();
	      });
	    }
	  }, {
	    key: '_doAuthed',
	    value: function _doAuthed(resource, method, options) {
	      var _this4 = this;
	
	      if (options === undefined) {
	        options = { refreshOnFailure: true, useRefreshToken: false };
	      } else {
	        if (options.refreshOnFailure === undefined) {
	          options.refreshOnFailure = true;
	        }
	        if (options.useRefreshToken === undefined) {
	          options.useRefreshToken = false;
	        }
	      }
	
	      if (this.auth() === null) {
	        return Promise.reject(new BaasError('Must auth first'));
	      }
	
	      var url = '' + this.appUrl + resource;
	
	      var headers = {
	        'Accept': 'application/json',
	        'Content-Type': 'application/json'
	      };
	      var token = options.useRefreshToken ? localStorage.getItem(REFRESH_TOKEN_KEY) : this.auth()['accessToken'];
	      headers['Authorization'] = 'Bearer ' + token;
	
	      var init = {
	        method: method,
	        headers: headers
	      };
	
	      if (options.body) {
	        init['body'] = options.body;
	      }
	
	      if (options.queryParams) {
	        url = url + '?' + toQueryString(options.queryParams);
	      }
	
	      return fetch(url, init).then(function (response) {
	        // Okay: passthrough
	        if (response.status >= 200 && response.status < 300) {
	          return Promise.resolve(response);
	        } else if (response.headers.get('Content-Type') === 'application/json') {
	          return response.json().then(function (json) {
	            // Only want to try refreshing token when there's an invalid session
	            if ('errorCode' in json && json['errorCode'] === ErrInvalidSession) {
	              if (!options.refreshOnFailure) {
	                _this4.authManager.clear();
	                var _error = new BaasError(json['error'], json['errorCode']);
	                _error.response = response;
	                throw _error;
	              }
	
	              return _this4._refreshToken().then(function () {
	                options.refreshOnFailure = false;
	                return _this4._doAuthed(resource, method, options);
	              });
	            }
	
	            var error = new BaasError(json['error'], json['errorCode']);
	            error.response = response;
	            throw error;
	          });
	        }
	
	        var error = new Error(response.statusText);
	        error.response = response;
	        throw error;
	      });
	    }
	  }, {
	    key: '_refreshToken',
	    value: function _refreshToken() {
	      var _this5 = this;
	
	      return this._doAuthed('/auth/newAccessToken', 'POST', { refreshOnFailure: false, useRefreshToken: true }).then(function (response) {
	        return response.json().then(function (json) {
	          _this5.authManager.setAccessToken(json['accessToken']);
	          return Promise.resolve();
	        });
	      });
	    }
	  }, {
	    key: 'executePipeline',
	    value: function executePipeline(stages) {
	      return this._doAuthed('/pipeline', 'POST', { body: JSON.stringify(stages) }).then(function (response) {
	        return response.json();
	      });
	    }
	  }]);
	
	  return BaasClient;
	}();
	
	var DB = function () {
	  function DB(client, service, name) {
	    _classCallCheck(this, DB);
	
	    this.client = client;
	    this.service = service;
	    this.name = name;
	  }
	
	  _createClass(DB, [{
	    key: 'getCollection',
	    value: function getCollection(name) {
	      return new Collection(this, name);
	    }
	  }]);
	
	  return DB;
	}();
	
	var Collection = function () {
	  function Collection(db, name) {
	    _classCallCheck(this, Collection);
	
	    this.db = db;
	    this.name = name;
	  }
	
	  _createClass(Collection, [{
	    key: 'getBaseArgs',
	    value: function getBaseArgs() {
	      return {
	        'database': this.db.name,
	        'collection': this.name
	      };
	    }
	  }, {
	    key: 'deleteOne',
	    value: function deleteOne(query) {
	      var args = this.getBaseArgs();
	      args.query = query;
	      args.singleDoc = true;
	      return this.db.client.executePipeline([{
	        'service': this.db.service,
	        'action': 'delete',
	        'args': args
	      }]);
	    }
	  }, {
	    key: 'deleteMany',
	    value: function deleteMany(query) {
	      var args = this.getBaseArgs();
	      args.query = query;
	      args.singleDoc = false;
	      return this.db.client.executePipeline([{
	        'service': this.db.service,
	        'action': 'delete',
	        'args': args
	      }]);
	    }
	  }, {
	    key: 'find',
	    value: function find(query, project) {
	      var args = this.getBaseArgs();
	      args.query = query;
	      args.project = project;
	      return this.db.client.executePipeline([{
	        'service': this.db.service,
	        'action': 'find',
	        'args': args
	      }]);
	    }
	  }, {
	    key: 'insert',
	    value: function insert(documents) {
	      return this.db.client.executePipeline([{ 'action': 'literal',
	        'args': {
	          'items': documents
	        }
	      }, {
	        'service': this.db.service,
	        'action': 'insert',
	        'args': this.getBaseArgs()
	      }]);
	    }
	  }, {
	    key: 'makeUpdateStage',
	    value: function makeUpdateStage(query, update, upsert, multi) {
	      var args = this.getBaseArgs();
	      args.query = query;
	      args.update = update;
	      if (upsert) {
	        args.upsert = true;
	      }
	      if (multi) {
	        args.multi = true;
	      }
	
	      return {
	        'service': this.db.service,
	        'action': 'update',
	        'args': args
	      };
	    }
	  }, {
	    key: 'updateOne',
	    value: function updateOne(query, update) {
	      return this.db.client.executePipeline([this.makeUpdateStage(query, update, false, false)]);
	    }
	  }, {
	    key: 'updateMany',
	    value: function updateMany(query, update, upsert, multi) {
	      return this.db.client.executePipeline([this.makeUpdateStage(query, update, false, true)]);
	    }
	  }, {
	    key: 'upsert',
	    value: function upsert(query, update) {
	      return this.db.client.executePipeline([this.makeUpdateStage(query, update, true, false)]);
	    }
	  }]);
	
	  return Collection;
	}();
	
	var MongoClient = exports.MongoClient = function () {
	  function MongoClient(baasClient, serviceName) {
	    _classCallCheck(this, MongoClient);
	
	    this.baasClient = baasClient;
	    this.service = serviceName;
	  }
	
	  _createClass(MongoClient, [{
	    key: 'getDb',
	    value: function getDb(name) {
	      return new DB(this.baasClient, this.service, name);
	    }
	  }]);
	
	  return MongoClient;
	}();
	
	var Admin = exports.Admin = function () {
	  function Admin(baseUrl) {
	    _classCallCheck(this, Admin);
	
	    this.client = new BaasClient('', { baseUrl: baseUrl });
	  }
	
	  _createClass(Admin, [{
	    key: '_doAuthed',
	    value: function _doAuthed(url, method, options) {
	      // TODO is this even necessary?
	      return this.client._doAuthed(url, method, options).then(function (response) {
	        return response.json();
	      });
	    }
	  }, {
	    key: '_get',
	    value: function _get(url, queryParams) {
	      return this._doAuthed(url, 'GET', { queryParams: queryParams });
	    }
	  }, {
	    key: '_put',
	    value: function _put(url, queryParams) {
	      return this._doAuthed(url, 'PUT', { queryParams: queryParams });
	    }
	  }, {
	    key: '_delete',
	    value: function _delete(url) {
	      return this._doAuthed(url, 'DELETE');
	    }
	  }, {
	    key: '_post',
	    value: function _post(url, body) {
	      return this._doAuthed(url, 'POST', { body: JSON.stringify(body) });
	    }
	  }, {
	    key: 'profile',
	    value: function profile() {
	      var root = this;
	      return {
	        keys: function keys() {
	          return {
	            list: function list() {
	              return root._get('/profile/keys');
	            },
	            create: function create(key) {
	              return root._post('/profile/keys');
	            },
	            key: function key(keyId) {
	              return {
	                get: function get() {
	                  return root._get('/profile/keys/' + keyId);
	                },
	                enable: function enable() {
	                  return root._put('/profile/keys/' + keyId + '/enable');
	                },
	                disable: function disable() {
	                  return root._put('/profile/keys/' + keyId + '/disable');
	                }
	              };
	            }
	          };
	        }
	      };
	    }
	
	    /* Examples of how to access admin API with this client:
	     *
	     * List all apps
	     *    a.apps().list()
	     *
	     * Fetch app under name "planner"
	     *    a.apps().app("planner").get()
	     *
	     * List services under the app "planner"
	     *    a.apps().app("planner").services().list()
	     *
	     * Delete a rule by ID
	     *    a.apps().app("planner").services().service("mdb1").rules().rule("580e6d055b199c221fcb821d").remove()
	     *
	     */
	
	  }, {
	    key: 'apps',
	    value: function apps() {
	      var _this6 = this;
	
	      var root = this;
	      return {
	        list: function list() {
	          return root._get('/apps');
	        },
	        create: function create(data) {
	          return root._post('/apps', data);
	        },
	        app: function app(_app) {
	          return {
	            get: function get() {
	              return root._get('/apps/' + _app);
	            },
	            remove: function remove() {
	              return root._delete('/apps/' + _app);
	            },
	
	            authProviders: function authProviders() {
	              return {
	                create: function create(data) {
	                  return _this6._post('/apps/' + _app + '/authProviders', data);
	                },
	                list: function list() {
	                  return _this6._get('/apps/' + _app + '/authProviders');
	                },
	                provider: function provider(authType, authName) {
	                  return {
	                    get: function get() {
	                      return _this6._get('/apps/' + _app + '/authProviders/' + authType + '/' + authName);
	                    },
	                    remove: function remove() {
	                      return _this6._delete('/apps/' + _app + '/authProviders/' + authType + '/' + authName);
	                    },
	                    update: function update(data) {
	                      return _this6._post('/apps/' + _app + '/authProviders/' + authType + '/' + authName, data);
	                    }
	                  };
	                }
	              };
	            },
	            variables: function variables() {
	              return {
	                list: function list() {
	                  return _this6._get('/apps/' + _app + '/vars');
	                },
	                create: function create(data) {
	                  return _this6._post('/apps/' + _app + '/vars', data);
	                },
	                variable: function variable(varName) {
	                  return {
	                    get: function get() {
	                      return _this6._get('/apps/' + _app + '/vars/' + varName);
	                    },
	                    remove: function remove() {
	                      return _this6._delete('/apps/' + _app + '/vars/' + varName);
	                    },
	                    update: function update(data) {
	                      return _this6._post('/apps/' + _app + '/vars/' + varName, data);
	                    }
	                  };
	                }
	              };
	            },
	            logs: function logs() {
	              return {
	                get: function get(filter) {
	                  return _this6._get('/apps/' + _app + '/logs', filter);
	                }
	              };
	            },
	
	            services: function services() {
	              return {
	                list: function list() {
	                  return _this6._get('/apps/' + _app + '/services');
	                },
	                create: function create(data) {
	                  return _this6._post('/apps/' + _app + '/services', data);
	                },
	                service: function service(svc) {
	                  return {
	                    get: function get() {
	                      return _this6._get('/apps/' + _app + '/services/' + svc);
	                    },
	                    update: function update(data) {
	                      return _this6._post('/apps/' + _app + '/services/' + svc, data);
	                    },
	                    remove: function remove() {
	                      return _this6._delete('/apps/' + _app + '/services/' + svc);
	                    },
	                    setConfig: function setConfig(data) {
	                      return _this6._post('/apps/' + _app + '/services/' + svc + '/config', data);
	                    },
	
	                    rules: function rules() {
	                      return {
	                        list: function list() {
	                          return _this6._get('/apps/' + _app + '/services/' + svc + '/rules');
	                        },
	                        create: function create(data) {
	                          return _this6._post('/apps/' + _app + '/services/' + svc + '/rules');
	                        },
	                        rule: function rule(ruleId) {
	                          return {
	                            get: function get() {
	                              return _this6._get('/apps/' + _app + '/services/' + svc + '/rules/' + ruleId);
	                            },
	                            update: function update(data) {
	                              return _this6._post('/apps/' + _app + '/services/' + svc + '/rules/' + ruleId, data);
	                            },
	                            remove: function remove() {
	                              return _this6._delete('/apps/' + _app + '/services/' + svc + '/rules/' + ruleId);
	                            }
	                          };
	                        }
	                      };
	                    },
	
	                    triggers: function triggers() {
	                      return {
	                        list: function list() {
	                          return _this6._get('/apps/' + _app + '/services/' + svc + '/triggers');
	                        },
	                        create: function create(data) {
	                          return _this6._post('/apps/' + _app + '/services/' + svc + '/triggers');
	                        },
	                        trigger: function trigger(triggerId) {
	                          return {
	                            get: function get() {
	                              return _this6._get('/apps/' + _app + '/services/' + svc + '/triggers/' + triggerId);
	                            },
	                            update: function update(data) {
	                              return _this6._post('/apps/' + _app + '/services/' + svc + '/triggers/' + triggerId, data);
	                            },
	                            remove: function remove() {
	                              return _this6._delete('/apps/' + _app + '/services/' + svc + '/triggers/' + triggerId);
	                            }
	                          };
	                        }
	                      };
	                    }
	                  };
	                }
	              };
	            }
	          };
	        }
	      };
	    }
	  }]);
	
	  return Admin;
	}();

/***/ },
/* 1 */
/***/ function(module, exports) {

	(function(self) {
	  'use strict';
	
	  if (self.fetch) {
	    return
	  }
	
	  var support = {
	    searchParams: 'URLSearchParams' in self,
	    iterable: 'Symbol' in self && 'iterator' in Symbol,
	    blob: 'FileReader' in self && 'Blob' in self && (function() {
	      try {
	        new Blob()
	        return true
	      } catch(e) {
	        return false
	      }
	    })(),
	    formData: 'FormData' in self,
	    arrayBuffer: 'ArrayBuffer' in self
	  }
	
	  if (support.arrayBuffer) {
	    var viewClasses = [
	      '[object Int8Array]',
	      '[object Uint8Array]',
	      '[object Uint8ClampedArray]',
	      '[object Int16Array]',
	      '[object Uint16Array]',
	      '[object Int32Array]',
	      '[object Uint32Array]',
	      '[object Float32Array]',
	      '[object Float64Array]'
	    ]
	
	    var isDataView = function(obj) {
	      return obj && DataView.prototype.isPrototypeOf(obj)
	    }
	
	    var isArrayBufferView = ArrayBuffer.isView || function(obj) {
	      return obj && viewClasses.indexOf(Object.prototype.toString.call(obj)) > -1
	    }
	  }
	
	  function normalizeName(name) {
	    if (typeof name !== 'string') {
	      name = String(name)
	    }
	    if (/[^a-z0-9\-#$%&'*+.\^_`|~]/i.test(name)) {
	      throw new TypeError('Invalid character in header field name')
	    }
	    return name.toLowerCase()
	  }
	
	  function normalizeValue(value) {
	    if (typeof value !== 'string') {
	      value = String(value)
	    }
	    return value
	  }
	
	  // Build a destructive iterator for the value list
	  function iteratorFor(items) {
	    var iterator = {
	      next: function() {
	        var value = items.shift()
	        return {done: value === undefined, value: value}
	      }
	    }
	
	    if (support.iterable) {
	      iterator[Symbol.iterator] = function() {
	        return iterator
	      }
	    }
	
	    return iterator
	  }
	
	  function Headers(headers) {
	    this.map = {}
	
	    if (headers instanceof Headers) {
	      headers.forEach(function(value, name) {
	        this.append(name, value)
	      }, this)
	
	    } else if (headers) {
	      Object.getOwnPropertyNames(headers).forEach(function(name) {
	        this.append(name, headers[name])
	      }, this)
	    }
	  }
	
	  Headers.prototype.append = function(name, value) {
	    name = normalizeName(name)
	    value = normalizeValue(value)
	    var oldValue = this.map[name]
	    this.map[name] = oldValue ? oldValue+','+value : value
	  }
	
	  Headers.prototype['delete'] = function(name) {
	    delete this.map[normalizeName(name)]
	  }
	
	  Headers.prototype.get = function(name) {
	    name = normalizeName(name)
	    return this.has(name) ? this.map[name] : null
	  }
	
	  Headers.prototype.has = function(name) {
	    return this.map.hasOwnProperty(normalizeName(name))
	  }
	
	  Headers.prototype.set = function(name, value) {
	    this.map[normalizeName(name)] = normalizeValue(value)
	  }
	
	  Headers.prototype.forEach = function(callback, thisArg) {
	    for (var name in this.map) {
	      if (this.map.hasOwnProperty(name)) {
	        callback.call(thisArg, this.map[name], name, this)
	      }
	    }
	  }
	
	  Headers.prototype.keys = function() {
	    var items = []
	    this.forEach(function(value, name) { items.push(name) })
	    return iteratorFor(items)
	  }
	
	  Headers.prototype.values = function() {
	    var items = []
	    this.forEach(function(value) { items.push(value) })
	    return iteratorFor(items)
	  }
	
	  Headers.prototype.entries = function() {
	    var items = []
	    this.forEach(function(value, name) { items.push([name, value]) })
	    return iteratorFor(items)
	  }
	
	  if (support.iterable) {
	    Headers.prototype[Symbol.iterator] = Headers.prototype.entries
	  }
	
	  function consumed(body) {
	    if (body.bodyUsed) {
	      return Promise.reject(new TypeError('Already read'))
	    }
	    body.bodyUsed = true
	  }
	
	  function fileReaderReady(reader) {
	    return new Promise(function(resolve, reject) {
	      reader.onload = function() {
	        resolve(reader.result)
	      }
	      reader.onerror = function() {
	        reject(reader.error)
	      }
	    })
	  }
	
	  function readBlobAsArrayBuffer(blob) {
	    var reader = new FileReader()
	    var promise = fileReaderReady(reader)
	    reader.readAsArrayBuffer(blob)
	    return promise
	  }
	
	  function readBlobAsText(blob) {
	    var reader = new FileReader()
	    var promise = fileReaderReady(reader)
	    reader.readAsText(blob)
	    return promise
	  }
	
	  function readArrayBufferAsText(buf) {
	    var view = new Uint8Array(buf)
	    var chars = new Array(view.length)
	
	    for (var i = 0; i < view.length; i++) {
	      chars[i] = String.fromCharCode(view[i])
	    }
	    return chars.join('')
	  }
	
	  function bufferClone(buf) {
	    if (buf.slice) {
	      return buf.slice(0)
	    } else {
	      var view = new Uint8Array(buf.byteLength)
	      view.set(new Uint8Array(buf))
	      return view.buffer
	    }
	  }
	
	  function Body() {
	    this.bodyUsed = false
	
	    this._initBody = function(body) {
	      this._bodyInit = body
	      if (!body) {
	        this._bodyText = ''
	      } else if (typeof body === 'string') {
	        this._bodyText = body
	      } else if (support.blob && Blob.prototype.isPrototypeOf(body)) {
	        this._bodyBlob = body
	      } else if (support.formData && FormData.prototype.isPrototypeOf(body)) {
	        this._bodyFormData = body
	      } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
	        this._bodyText = body.toString()
	      } else if (support.arrayBuffer && support.blob && isDataView(body)) {
	        this._bodyArrayBuffer = bufferClone(body.buffer)
	        // IE 10-11 can't handle a DataView body.
	        this._bodyInit = new Blob([this._bodyArrayBuffer])
	      } else if (support.arrayBuffer && (ArrayBuffer.prototype.isPrototypeOf(body) || isArrayBufferView(body))) {
	        this._bodyArrayBuffer = bufferClone(body)
	      } else {
	        throw new Error('unsupported BodyInit type')
	      }
	
	      if (!this.headers.get('content-type')) {
	        if (typeof body === 'string') {
	          this.headers.set('content-type', 'text/plain;charset=UTF-8')
	        } else if (this._bodyBlob && this._bodyBlob.type) {
	          this.headers.set('content-type', this._bodyBlob.type)
	        } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
	          this.headers.set('content-type', 'application/x-www-form-urlencoded;charset=UTF-8')
	        }
	      }
	    }
	
	    if (support.blob) {
	      this.blob = function() {
	        var rejected = consumed(this)
	        if (rejected) {
	          return rejected
	        }
	
	        if (this._bodyBlob) {
	          return Promise.resolve(this._bodyBlob)
	        } else if (this._bodyArrayBuffer) {
	          return Promise.resolve(new Blob([this._bodyArrayBuffer]))
	        } else if (this._bodyFormData) {
	          throw new Error('could not read FormData body as blob')
	        } else {
	          return Promise.resolve(new Blob([this._bodyText]))
	        }
	      }
	
	      this.arrayBuffer = function() {
	        if (this._bodyArrayBuffer) {
	          return consumed(this) || Promise.resolve(this._bodyArrayBuffer)
	        } else {
	          return this.blob().then(readBlobAsArrayBuffer)
	        }
	      }
	    }
	
	    this.text = function() {
	      var rejected = consumed(this)
	      if (rejected) {
	        return rejected
	      }
	
	      if (this._bodyBlob) {
	        return readBlobAsText(this._bodyBlob)
	      } else if (this._bodyArrayBuffer) {
	        return Promise.resolve(readArrayBufferAsText(this._bodyArrayBuffer))
	      } else if (this._bodyFormData) {
	        throw new Error('could not read FormData body as text')
	      } else {
	        return Promise.resolve(this._bodyText)
	      }
	    }
	
	    if (support.formData) {
	      this.formData = function() {
	        return this.text().then(decode)
	      }
	    }
	
	    this.json = function() {
	      return this.text().then(JSON.parse)
	    }
	
	    return this
	  }
	
	  // HTTP methods whose capitalization should be normalized
	  var methods = ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'POST', 'PUT']
	
	  function normalizeMethod(method) {
	    var upcased = method.toUpperCase()
	    return (methods.indexOf(upcased) > -1) ? upcased : method
	  }
	
	  function Request(input, options) {
	    options = options || {}
	    var body = options.body
	
	    if (input instanceof Request) {
	      if (input.bodyUsed) {
	        throw new TypeError('Already read')
	      }
	      this.url = input.url
	      this.credentials = input.credentials
	      if (!options.headers) {
	        this.headers = new Headers(input.headers)
	      }
	      this.method = input.method
	      this.mode = input.mode
	      if (!body && input._bodyInit != null) {
	        body = input._bodyInit
	        input.bodyUsed = true
	      }
	    } else {
	      this.url = String(input)
	    }
	
	    this.credentials = options.credentials || this.credentials || 'omit'
	    if (options.headers || !this.headers) {
	      this.headers = new Headers(options.headers)
	    }
	    this.method = normalizeMethod(options.method || this.method || 'GET')
	    this.mode = options.mode || this.mode || null
	    this.referrer = null
	
	    if ((this.method === 'GET' || this.method === 'HEAD') && body) {
	      throw new TypeError('Body not allowed for GET or HEAD requests')
	    }
	    this._initBody(body)
	  }
	
	  Request.prototype.clone = function() {
	    return new Request(this, { body: this._bodyInit })
	  }
	
	  function decode(body) {
	    var form = new FormData()
	    body.trim().split('&').forEach(function(bytes) {
	      if (bytes) {
	        var split = bytes.split('=')
	        var name = split.shift().replace(/\+/g, ' ')
	        var value = split.join('=').replace(/\+/g, ' ')
	        form.append(decodeURIComponent(name), decodeURIComponent(value))
	      }
	    })
	    return form
	  }
	
	  function parseHeaders(rawHeaders) {
	    var headers = new Headers()
	    rawHeaders.split(/\r?\n/).forEach(function(line) {
	      var parts = line.split(':')
	      var key = parts.shift().trim()
	      if (key) {
	        var value = parts.join(':').trim()
	        headers.append(key, value)
	      }
	    })
	    return headers
	  }
	
	  Body.call(Request.prototype)
	
	  function Response(bodyInit, options) {
	    if (!options) {
	      options = {}
	    }
	
	    this.type = 'default'
	    this.status = 'status' in options ? options.status : 200
	    this.ok = this.status >= 200 && this.status < 300
	    this.statusText = 'statusText' in options ? options.statusText : 'OK'
	    this.headers = new Headers(options.headers)
	    this.url = options.url || ''
	    this._initBody(bodyInit)
	  }
	
	  Body.call(Response.prototype)
	
	  Response.prototype.clone = function() {
	    return new Response(this._bodyInit, {
	      status: this.status,
	      statusText: this.statusText,
	      headers: new Headers(this.headers),
	      url: this.url
	    })
	  }
	
	  Response.error = function() {
	    var response = new Response(null, {status: 0, statusText: ''})
	    response.type = 'error'
	    return response
	  }
	
	  var redirectStatuses = [301, 302, 303, 307, 308]
	
	  Response.redirect = function(url, status) {
	    if (redirectStatuses.indexOf(status) === -1) {
	      throw new RangeError('Invalid status code')
	    }
	
	    return new Response(null, {status: status, headers: {location: url}})
	  }
	
	  self.Headers = Headers
	  self.Request = Request
	  self.Response = Response
	
	  self.fetch = function(input, init) {
	    return new Promise(function(resolve, reject) {
	      var request = new Request(input, init)
	      var xhr = new XMLHttpRequest()
	
	      xhr.onload = function() {
	        var options = {
	          status: xhr.status,
	          statusText: xhr.statusText,
	          headers: parseHeaders(xhr.getAllResponseHeaders() || '')
	        }
	        options.url = 'responseURL' in xhr ? xhr.responseURL : options.headers.get('X-Request-URL')
	        var body = 'response' in xhr ? xhr.response : xhr.responseText
	        resolve(new Response(body, options))
	      }
	
	      xhr.onerror = function() {
	        reject(new TypeError('Network request failed'))
	      }
	
	      xhr.ontimeout = function() {
	        reject(new TypeError('Network request failed'))
	      }
	
	      xhr.open(request.method, request.url, true)
	
	      if (request.credentials === 'include') {
	        xhr.withCredentials = true
	      }
	
	      if ('responseType' in xhr && support.blob) {
	        xhr.responseType = 'blob'
	      }
	
	      request.headers.forEach(function(value, name) {
	        xhr.setRequestHeader(name, value)
	      })
	
	      xhr.send(typeof request._bodyInit === 'undefined' ? null : request._bodyInit)
	    })
	  }
	  self.fetch.polyfill = true
	})(typeof self !== 'undefined' ? self : this);


/***/ }
/******/ ]);
//# sourceMappingURL=baas.js.map