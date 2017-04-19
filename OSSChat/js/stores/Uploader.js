import { observable, computed, action } from 'mobx';
import uploadAsset from './uploadAsset';
import FeedItem from './FeedItem';

export default class Uploader {
  baas;

  @observable localAsset;
  @observable uploading = false;

  @action setLocalAsset({ path, isVideo }) {
    this.localAsset = {
      path,
      isVideo,
      groups: observable.map(),
      @computed get hasSelectedGroups() {
        return this.groups.size > 0;
      },
    };
  }

  @computed get hasLocalAsset() {
    return this.localAsset && this.localAsset.path;
  }

  @action clearLocalAsset() {
    this.localAsset = null;
  }

  @action toggleGroup({ id }) {
    if (this.localAsset.groups.has(id.toString())) {
      this.localAsset.groups.delete(id.toString());
    } else {
      this.localAsset.groups.set(id.toString(), true);
    }
  }

  @action async upload() {
    this.uploading = true;

    const { path, isVideo, groups } = this.localAsset;

    const remoteUrl = await uploadAsset({
      baasClient: this.baas.baasClient,
      localPath: path,
      isVideo,
    });

    const feedItem = FeedItem.createLocal({ path, isVideo, baas: this.baas });

    feedItem.media.url = decodeURIComponent(remoteUrl);

    const insertData = {
      ...feedItem.toJSON(),
      groups: groups.keys(),
      owner_id: '$$user.id',
    };

    const db = this.baas.getDb();

    let response;
    try {
      response = await db.collection('items').insert([insertData]);
    } catch (e) {
      this.uploading = false;
      throw e;
    }

    feedItem.ownerId = this.baas.baasClient.auth()._id

    this.clearLocalAsset();
    this.uploading = false;

    return feedItem;
  }
}
