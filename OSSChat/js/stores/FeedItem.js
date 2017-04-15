import _ from 'lodash';
// const example = {
//   owner_id: 'id',
//   media_type: ['image', 'video'],
//   public_url: 'http',
//   groups: ['web', 'design'],
// }

class FeedMedia {
  static Types = {
    Image: 'image',
    Video: 'video',
  };

  constructor(
    {
      type,
      url,
      localPath,
    },
  ) {
    this.localPath = localPath;
    this.url = url;
    this.type = type;
  }

  set type(type) {
    if (type == null) {
      return;
    }

    if (!FeedMedia.ValidTypes.includes(type)) {
      throw new Error(
        `FeedMedia.type must be one of ${JSON.stringify(
          FeedMedia.ValidTypes,
        )}.`,
      );
    }
    this._type = type;
  }

  get type() {
    return this._type;
  }

  isVideo() {
    return this.type === FeedMedia.Types.Video;
  }
}
FeedMedia.ValidTypes = _.values(FeedMedia.Types);

export default class FeedItem {
  id;
  ownerId;
  groups;
  media;
  dateCreated;

  constructor({ media, dateCreated }) {
    this.media = media;
    this.dateCreated = dateCreated;
  }

  static createFromDb(dbValue) {
    const media = new FeedMedia(dbValue.media);

    const feedItem = new FeedItem({
      media,
    });

    feedItem.dateCreated = dbValue.dateCreated;
    feedItem.groups = dbValue.groups;
    feedItem.id = dbValue._id; // eslint-disable-line
    feedItem.ownerId = dbValue.owner_id;

    return feedItem;
  }

  static createLocal({ path, isVideo }) {
    const type = isVideo ? FeedMedia.Types.Video : FeedMedia.Types.Image;
    const media = new FeedMedia({
      localPath: path,
      type,
    });

    return new FeedItem({
      media,
      dateCreated: new Date(),
    });
  }

  set groups(groups) {
    if (groups == null) {
      return;
    }
    if (!Array.isArray(groups)) {
      throw new Error('FeedItem.groups must be an array.');
    }
    this._groups = groups;
  }

  get groups() {
    return this._groups;
  }

  toJSON() {
    return {
      owner_id: this.ownerId,
      groups: this.groups,
      dateCreated: this.dateCreated,
      media: {
        type: this.media.type,
        url: this.media.url,
      },
    };
  }
}
