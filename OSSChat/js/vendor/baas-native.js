import { AsyncStorage } from 'react-native';
import _ from 'lodash';
import { encode, decode } from 'base-64';
export * from './baas';
import { setupReactNative } from './baas';

const window = {
  atob: decode,
  btoa: encode,
};
const localStorage = {
  store: {},
  getItem(val) {
    const res = this.store[val];
    return res || null;
  },
  setItem(key, val) {
    saveLocalStorage();
    return this.store[key] = val;
  },
  removeItem(val) {
    saveLocalStorage();
    delete this.store[val];
  },
};

const localStorageKey = 'bananas';
export async function loadLocalStorage() {
  const store = await AsyncStorage.getItem(localStorageKey);
  localStorage.store = JSON.parse(store) || {};
}
const saveLocalStorage = _.debounce(
  () => {
    AsyncStorage.setItem(localStorageKey, JSON.stringify(localStorage.store));
  },
  100,
);

setupReactNative({ window, localStorage });
