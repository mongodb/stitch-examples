class MemoryStorage {
  constructor() {
    this._data = {};
  }

  getItem(key) {
    return (key in this._data) ? this._data[key] : null;
  }

  setItem(key, value) {
    this._data[key] = value;
    return this._data[key];
  }

  removeItem(key) {
    delete this._data[key];
    return undefined;
  }

  clear() {
    this._data = {};
    return this._data;
  }
}

class Storage {
  constructor(store) {
    this.store = store;
  }

  get(key) { return this.store.getItem(key); }
  set(key, value) { return this.store.setItem(key, value); }
  remove(key) { return this.store.removeItem(key); }
  clear() { return this.store.clear(); }
}

export function createStorage(type) {
  if (type === 'localStorage') {
    if ((typeof window !== 'undefined') && 'localStorage' in window && window.localStorage !== null) {
      return new Storage(window.localStorage);
    }
  } else if (type === 'sessionStorage') {
    if ((typeof window !== 'undefined') && 'sessionStorage' in window && window.sessionStorage !== null) {
      return new Storage(window.sessionStorage);
    }
  }

  // default to memory storage
  return new Storage(new MemoryStorage());
}
