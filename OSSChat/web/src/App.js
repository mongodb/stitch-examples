import './App.css';

import React, { Component } from 'react';
import { observer, inject } from 'mobx-react';

@inject('uiState')
@observer
class FeedItemSlides extends Component {
  // eslint-disable-next-line
  groupViewer = this.props.uiState.createGroupViewer({
    group: this.props.group,
    onCompleted: this.props.close,
  });

  componentDidMount() {
    this.groupViewer.createAutoAdvanceTimer();
  }

  componentWillUnmount() {
    this.props.uiState.destroyGroupViewer();
  }

  tapNavigate = direction => () => {
    this.groupViewer.stopAutoAdvance();
    direction();
    this.groupViewer.createAutoAdvanceTimer();
  };

  render() {
    const { media } = this.groupViewer.currentFeedItem;
    return (
      <div>
        {media.isVideo()
          ? <video className="Group-asset" src={media.url} autoPlay />
          : <img className="Group-asset" src={media.url} />}
      </div>
    );
  }
}

class GroupRow extends Component {
  state = {
    expanded: false,
  };

  toggleExpanded = () => this.setState({ expanded: !this.state.expanded });

  render() {
    const { name } = this.props.group;
    return (
      <div>
        <h1 className="Group-heading" onClick={this.toggleExpanded}>{name}</h1>
        {this.state.expanded && <FeedItemSlides group={this.props.group} />}
      </div>
    );
  }
}

@inject('groupStore')
@observer
export default class App extends Component {
  render() {
    return (
      <div className="App">
        <div className="App-heading App-flex">
          <h2><span className="App-react">NapHat</span></h2>
        </div>
        <div className="App-instructions">
          {this.props.groupStore.groups.map(group => (
            <GroupRow key={group.id} group={group} />
          ))}
        </div>
      </div>
    );
  }
}
