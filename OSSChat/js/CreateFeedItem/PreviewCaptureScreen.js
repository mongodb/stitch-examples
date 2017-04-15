import React, { Component } from 'react';
import { StyleSheet, View, Dimensions } from 'react-native';
import { observer, inject } from 'mobx-react/native';
import Icon from 'react-native-vector-icons/FontAwesome';
import AssetPlayer from '../AssetPlayer';

const { width } = Dimensions.get('window');

@inject('uploader')
@observer
export default class PreviewCaptureScreen extends Component {
  state = {
    uploadComplete: false,
  };

  onClose = () => this.props.uploader.clearLocalAsset();

  render() {
    const { path, isVideo } = this.props.uploader.localAsset;

    return (
      <View style={styles.container}>
        <AssetPlayer
          isVideo={isVideo}
          uri={path}
          paused={!this.props.isCurrentSlide}
        />
        <Icon
          name="hand-peace-o"
          color="white"
          size={40}
          style={styles.close}
          onPress={this.onClose}
        />
        <Icon
          name="arrow-circle-right"
          color="white"
          size={40}
          style={styles.goForward}
          onPress={this.props.goForward}
        />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: 'transparent' },
  footer: {
    flex: 1,
    position: 'absolute',
    left: 0,
    bottom: 40,
    width,
    flexDirection: 'row',
    justifyContent: 'space-around',
  },
  close: {
    position: 'absolute',
    right: 30,
    top: 40,
  },
  goForward: {
    position: 'absolute',
    right: 30,
    bottom: 20,
  },
});
