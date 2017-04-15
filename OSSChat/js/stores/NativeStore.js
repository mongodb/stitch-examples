import { computed } from 'mobx';
import { ListView } from 'react-native';

export default class NativeStore {
  groupStore;

  feedDs = new ListView.DataSource({ rowHasChanged: (r1, r2) => r1 !== r2 });

  @computed get feedDataSource() {
    return this.feedDs.cloneWithRows(this.feedItems.slice());
  }

  groupDs = new ListView.DataSource({ rowHasChanged: (r1, r2) => r1 !== r2 });

  @computed get groupDataSource() {
    return this.groupDs.cloneWithRows(this.groupStore.groups.slice());
  }
}
