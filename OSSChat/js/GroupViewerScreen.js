import React, { Component } from 'react';
import {
  StyleSheet,
  View,
  Dimensions,
  TouchableWithoutFeedback,
} from 'react-native';
import { observer, inject } from 'mobx-react/native';
import Icon from 'react-native-vector-icons/FontAwesome';
import AssetPlayer from './AssetPlayer';

const { width, height } = Dimensions.get('window');

const BackWidth = Math.round(width * 0.3);
const ForwardWidth = Math.round(width * 0.7);

const NavigateTapView = ({ style, onPress }) => (
  <TouchableWithoutFeedback onPress={onPress}>
    <View style={[styles.tapTarget, style]} />
  </TouchableWithoutFeedback>
);

@inject('uiState')
@observer
export default class GroupViewerScreen extends Component {
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
      <View style={styles.container}>
        <AssetPlayer
          isVideo={media.isVideo()}
          uri={media.url}
          onEnd={this.groupViewer.autoAdvance}
          renderProgress
          onLoadEnd={this.groupViewer.createAutoAdvanceTimer}
        />
        <NavigateTapView
          onPress={this.tapNavigate(this.groupViewer.back)}
          style={styles.backTarget}
        />
        <NavigateTapView
          onPress={this.tapNavigate(this.groupViewer.forward)}
          style={styles.forwardTarget}
        />
        <Icon
          name="hand-peace-o"
          size={40}
          color="white"
          style={styles.close}
          onPress={this.props.close}
        />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#EEE' },
  close: {
    backgroundColor: 'transparent',
    position: 'absolute',
    right: 30,
    top: 40,
  },
  tapTarget: {
    position: 'absolute',
    backgroundColor: 'transparent',
    left: 0,
    height,
  },
  backTarget: {
    width: BackWidth,
  },
  forwardTarget: {
    left: BackWidth,
    width: ForwardWidth,
  },
});
