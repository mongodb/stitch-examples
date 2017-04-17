/**
 * @flow
 */

import React, { Component } from 'react';
import { StyleSheet, View } from 'react-native';
import { observer, Provider, inject } from 'mobx-react/native';

import Swiper from 'react-native-swiper';
import CameraScreen from './CameraScreen';
import GroupListScreen from './GroupListScreen';
import CreateFeedItemFlow from './CreateFeedItem/CreateFeedItemFlow';
import Stores from './stores/index-native';
import { BaasClient } from './vendor/baas/client';

const storesInstance = new Stores();

@inject('uploader', 'uiState')
@observer
class App extends Component {
  componentDidMount() {
    storesInstance.initialize({ BaasClient });
  }

  render() {
    if (this.props.uploader.hasLocalAsset) {
      return <CreateFeedItemFlow />;
    }
    return (
      <Swiper
        style={styles.wrapper}
        showsButtons={false}
        index={0}
        showsPagination={false}
        loop={false}
        scrollEnabled={this.props.uiState.scrollEnabled}
      >
        <View style={styles.slide2}>
          <CameraScreen />
        </View>
        <View style={styles.slide3}>
          <GroupListScreen />
        </View>
      </Swiper>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  slide1: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#9DD6EB',
  },
  slide2: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#97CAE5',
  },
  slide3: {
    flex: 1,
  },
  text: {
    color: '#fff',
    fontSize: 30,
    fontWeight: 'bold',
  },
});

export default () => (
  <Provider
    store={storesInstance}
    groupStore={storesInstance.groupStore}
    uploader={storesInstance.uploader}
    uiState={storesInstance.uiState}
    nativeStore={storesInstance.nativeStore}
  >
    <App />
  </Provider>
);
