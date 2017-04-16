export const JSONTYPE = 'application/json';
export const USER_AUTH_KEY = '_baas_ua';
export const REFRESH_TOKEN_KEY = '_baas_rt';
export const STATE_KEY = '_baas_state';
export const BAAS_ERROR_KEY = '_baas_error';
export const BAAS_LINK_KEY = '_baas_link';
export const IMPERSONATION_ACTIVE_KEY = '_baas_impers_active';
export const IMPERSONATION_USER_KEY = '_baas_impers_user';
export const IMPERSONATION_REAL_USER_AUTH_KEY = '_baas_impers_real_ua';
export const DEFAULT_BAAS_SERVER_URL = 'https://baas-dev.10gen.cc';

export const checkStatus = (response) => {
  if (response.status >= 200 && response.status < 300) {
    return response;
  }

  let error = new Error(response.statusText);
  error.response = response;
  throw error;
};

export const makeFetchArgs = (method, body) => {
  const init = {
    method: method,
    headers: { 'Accept': JSONTYPE, 'Content-Type': JSONTYPE }
  };

  if (body) {
    init.body = body;
  }
  init.cors = true;
  return init;
};

export const parseRedirectFragment = (fragment, ourState) => {
  // After being redirected from oauth, the URL will look like:
  // https://todo.examples.baas-dev.10gen.cc/#_baas_state=...&_baas_ua=...
  // This function parses out baas-specific tokens from the fragment and
  // builds an object describing the result.
  const vars = fragment.split('&');
  const result = { ua: null, found: false, stateValid: false, lastError: null };
  let shouldBreak = false;
  for (const pair of vars) {
    let pairParts = pair.split('=');
    const pairKey = decodeURIComponent(pairParts[0]);
    switch (pairKey) {
    case BAAS_ERROR_KEY:
      result.lastError = decodeURIComponent(pairParts[1]);
      result.found = true;
      shouldBreak = true;
      break;
    case USER_AUTH_KEY:
      result.ua = JSON.parse(window.atob(decodeURIComponent(pairParts[1])));
      result.found = true;
      continue;
    case BAAS_LINK_KEY:
      result.found = true;
      continue;
    case STATE_KEY:
      result.found = true;
      let theirState = decodeURIComponent(pairParts[1]);
      if (ourState && ourState === theirState) {
        result.stateValid = true;
      }
      continue;
    default: continue;
    }

    if (shouldBreak) {
      break;
    }
  }

  return result;
};
