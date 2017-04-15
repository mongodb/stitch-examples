import { observable, computed, action } from 'mobx';

const SlideSpeedMS = 3 * 1000;
class GroupViewer {
  @observable index = 0;

  constructor({ group, onCompleted }) {
    this.group = group;
    this.onCompleted = onCompleted;
  }

  @computed get currentFeedItem() {
    return this.group.feedItems[this.index];
  }

  createAutoAdvanceTimer = () => {
    clearTimeout(this.timer);

    const feedItem = this.currentFeedItem;

    if (feedItem.media.isVideo()) {
      return;
    }

    this.timer = setTimeout(
      this.autoAdvance,
      feedItem.imageLength || SlideSpeedMS,
    );
  };

  stopAutoAdvance() {
    clearTimeout(this.timer);
  }

  autoAdvance = () => {
    const allowed = this.forward();
    if (!allowed) {
      this.onCompleted();
      return;
    }

    this.createAutoAdvanceTimer();
  };

  indexWithinBounds = index =>
    index > -1 && index < this.group.feedItems.length;

  navigateIndex = computeNext => {
    const currentIndex = this.index;

    const nextIndex = computeNext(currentIndex);
    const permitted = this.indexWithinBounds(nextIndex);
    if (permitted) {
      this.index = nextIndex;
    }

    return permitted;
  };

  @action back = () => this.navigateIndex(i => i - 1);
  @action forward = () => this.navigateIndex(i => i + 1);
}

export default class UiState {
  @observable scrollEnabled = true;
  @observable groupViewer;

  createGroupViewer(...args) {
    this.groupViewer = new GroupViewer(...args);
    return this.groupViewer;
  }

  destroyGroupViewer() {
    this.groupViewer.stopAutoAdvance();
    this.groupViewer = null;
  }
}
