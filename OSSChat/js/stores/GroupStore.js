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
    const response = await db.collection('items').find();
    this.feedItems = response.map(FeedItem.createFromDb);

    await this.loadGroups();

    this.loading = false;
  }

  async loadGroups() {
    const db = this.baas.getDb();
    const groupsResponse = await db.collection('groups').find();
    const groupInstanceArray = groupsResponse.map(Group.createFromDb);

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

    await db.collection('groups').insert([doc]);
    await this.loadGroups();
  }
}
