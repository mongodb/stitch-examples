import NativeStore from './NativeStore';

import Store from './index';

export default class StoreNative extends Store {
  constructor(...args) {
    super(...args);

    this.nativeStore = new NativeStore();
    this.nativeStore.groupStore = this.groupStore;
  }
}
