import _ from 'lodash';
import { observable, observe } from 'mobx';
import BaaSService from './BaaSService';
import GroupStore from './GroupStore';
import Uploader from './Uploader';
import UiState from './UiState';

export default class Store {
  baas;
  viewer;

  @observable isReady = false;

  constructor() {
    this.groupStore = new GroupStore();
    this.uploader = new Uploader();
    this.uiState = new UiState();

    observe(this.uploader, 'uploading', change => {
      if (change.newValue === false) {
        this.groupStore.load();
      }
    });
  }

  async initialize({ BaasClient }) {
    this.baas = await BaaSService.create({
      BaasClient,
    });
    this.groupStore.baas = this.baas;
    this.uploader.baas = this.baas;

    await this.groupStore.load();

    this.isReady = true;
  }
}
