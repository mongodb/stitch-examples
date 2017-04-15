import React, { Component } from 'react';
import { StyleSheet, View } from 'react-native';
import { observer, inject } from 'mobx-react/native';

import Swiper from 'react-native-swiper';
import PreviewCaptureScreen from './PreviewCaptureScreen';
import ChooseGroupsScreen from './ChooseGroupsScreen';

@inject('uploader', 'uiState')
@observer
export default class CreateFeedItemFlow extends Component {
  state = {
    index: 0,
  };

  goForward = () => {
    this.swiper.scrollBy(1);
    this.setState({ index: this.state.index + 1 });
  }

  goBack = () => {
    this.swiper.scrollBy(-1);
    this.setState({ index: this.state.index - 1 });
  }

  render() {
    return (
      <Swiper
        ref={r => {
          this.swiper = r;
        }}
        style={styles.wrapper}
        index={0}
        showsButtons={false}
        showsPagination={false}
        loop={false}
        scrollEnabled={false}
      >
        <View style={styles.slide}>
          <PreviewCaptureScreen
            goForward={this.goForward}
            isCurrentSlide={this.state.index === 0}
          />
        </View>
        <View style={styles.slide}>
          <ChooseGroupsScreen
            goBack={this.goBack}
            isCurrentSlide={this.state.index === 0}
          />
        </View>
      </Swiper>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  slide: {
    flex: 1,
  },
});
