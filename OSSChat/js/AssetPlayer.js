import _ from 'lodash';
import React, { Component } from 'react';
import { View, Image, StyleSheet, Dimensions, ActivityIndicator } from 'react-native';
import Video from 'react-native-video';

const { width, height } = Dimensions.get('window');

export default class AssetPlayer extends Component {
  static defaultProps = {
    onEnd: _.noop,
    onLoadEnd: _.noop,
    renderProgress: false,
  };

  state = {
    loadProgress: 0,
  }

  onLoadStart = () => this.setState({ loadProgress: 0 });
  onLoadEnd = () => {
    this.setState({ loadProgress: 100 });
    this.props.onLoadEnd();
  }
  onLoadProgress = ({ nativeEvent: { loaded, total } }) => {
    this.setState({ loadProgress: Math.round(loaded / total * 100) });
  };

  renderProgress() {
    if (!this.props.renderProgress) {
      return false;
    }

    if (this.state.loadProgress === 100) {
      return null;
    }

    return (
      <ActivityIndicator name="cycle" size="large" style={styles.upload} />
    );
  }

  render() {
    const { uri, isVideo } = this.props;
    const source = { uri };

    let asset;

    if (isVideo) {
      const { onEnd, paused } = this.props;
      asset = (
        <Video
          source={source}
          style={styles.preview}
          repeat
          onEnd={onEnd}
          paused={paused}
          onLoadStart={this.onLoadStart}
          onLoad={this.onLoadEnd}
        />
      );
    } else {
      asset = (
        <Image
          source={source}
          style={styles.preview}
          onLoadStart={this.onLoadStart}
          onLoadEnd={this.onLoadEnd}
          onProgress={this.onLoadProgress}
        />
      );
    }

    return (
      <View style={styles.container}>
        {asset}
        {this.renderProgress()}
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  preview: {
    width,
    height,
  },
  upload: {
    backgroundColor: 'transparent',
    position: 'absolute',
    left: Math.round(width / 2 - 15),
    top: Math.round(height / 2 - 30),
  },
});
