import React, { Component } from 'react';
import {
  Dimensions,
  StyleSheet,
  View,
  TouchableWithoutFeedback,
} from 'react-native';
import Camera from 'react-native-camera';
import { observer, inject } from 'mobx-react/native';
import RecordButton from './RecordButton';

const AnimationDurationMs = 10 * 1000;
const DoublePressDelayMS = 300;

@inject('uploader', 'uiState')
@observer
export default class CameraScreen extends Component {
  state = {
    recordVideo: false,
    progress: 0,
    backCamera: true,
  };

  onPressIn = () => {
    this.props.uiState.scrollEnabled = false;

    this.pressedIn = true;
    this.videoTimeout = setTimeout(
      () => {
        this.setState({ recordVideo: true }, () => {
          this.videoPromise = this.camera.capture();
          this.startVideoProgress();
        });
      },
      300,
    );
  };

  onPressOut = async () => {
    this.props.uiState.scrollEnabled = true;

    this.pressedIn = false;

    clearTimeout(this.videoTimeout);
    this.videoTimeout = null;

    cancelAnimationFrame(this.animationFrame);
    this.animationFrame = null;

    let capturePromise;
    let isVideo = false;
    if (this.videoPromise) {
      this.camera.stopCapture();
      capturePromise = this.videoPromise;
      this.videoPromise = null;
      isVideo = true;
    } else {
      capturePromise = this.camera.capture();
    }

    let data;
    try {
      data = await capturePromise;
    } catch (err) {
      console.error(err);
    }

    this.setState({
      recordVideo: false,
      progress: 0,
    });

    this.props.uploader.setLocalAsset({
      isVideo,
      path: data.path,
    });
  };

  onScreenPress = () => {
    const now = new Date().getTime();

    if (this.lastImagePress && now - this.lastImagePress < DoublePressDelayMS) {
      delete this.lastImagePress;
      this.setState({ backCamera: !this.state.backCamera });
    } else {
      this.lastImagePress = now;
    }
  };

  startVideoProgress = start => {
    this.animationFrame = requestAnimationFrame(timestamp => {
      if (!this.pressedIn) {
        return;
      }
      if (!start) {
        // eslint-disable-next-line no-param-reassign
        start = timestamp;
      }

      const delta = (timestamp - start) / AnimationDurationMs;
      const progress = Math.round(100 * delta);

      this.setState({ progress });
      this.startVideoProgress(start);
    });
  };

  render() {
    return (
      <TouchableWithoutFeedback onPress={this.onScreenPress}>
        <View style={styles.container}>
          <Camera
            ref={cam => {
              this.camera = cam;
            }}
            style={styles.preview}
            mirrorImage={!this.state.recordVideo && !this.state.backCamera}
            type={
              this.state.backCamera
                ? Camera.constants.Type.back
                : Camera.constants.Type.front
            }
            captureAudio
            captureTarget={Camera.constants.CaptureTarget.disk}
            captureMode={
              this.state.recordVideo
                ? Camera.constants.CaptureMode.video
                : Camera.constants.CaptureMode.still
            }
            aspect={Camera.constants.Aspect.fill}
          >
            <RecordButton
              style={styles.recordButton}
              progress={this.state.progress}
              onPressIn={this.onPressIn}
              onPressOut={this.onPressOut}
            />
          </Camera>
        </View>
      </TouchableWithoutFeedback>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  preview: {
    flex: 1,
    justifyContent: 'flex-end',
    alignItems: 'center',
    height: Dimensions.get('window').height,
    width: Dimensions.get('window').width,
  },
  recordButton: {
    flex: 0,
    backgroundColor: 'transparent',
    marginBottom: 40,
  },
});
