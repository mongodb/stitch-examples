import { observable, action } from 'mobx';
import FeedItem from './FeedItem';

class Group {
  name;
  feedItems = [];

  static createFromDb(resp) {
    const instance = new Group();
    instance.id = resp._id; // eslint-disable-line
    instance.name = resp.name;
    return instance;
  }
}

export default class GroupStore {
  baas;

  @observable loading = false;
  @observable groups = [];
  @observable feedItems = [];

  @action.bound async load() {
    this.loading = true;
    const db = this.baas.getDb();
    const response = await db.getCollection('items').find();
    this.feedItems = response.result.map(FeedItem.createFromDb);

    this.loadGroups();

    this.loading = false;
  }

  async loadGroups() {
    const db = this.baas.getDb();
    const groupsResponse = await db.getCollection('groups').find();
    const groupInstanceArray = groupsResponse.result.map(Group.createFromDb);

    this.groups = groupInstanceArray.map(group => {
      // eslint-disable-next-line no-param-reassign
      group.feedItems = this.feedItems.filter(
        feedItem => {
          return feedItem.groups.includes(group.id.toString())
        }
      );

      return group;
    });
  }

  @action async createGroup({ name }) {
    const db = this.baas.getDb();

    const doc = {
      name,
    };

    await db.getCollection('groups').insert([doc]);
    await this.loadGroups();
  }
}
