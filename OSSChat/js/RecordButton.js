import React, { Component } from 'react';
import {
  StyleSheet,
  TouchableWithoutFeedback,
  View,
  Dimensions,
} from 'react-native';
import { AnimatedCircularProgress } from 'react-native-circular-progress';

const { height, width } = Dimensions.get('window');

const hitSlop = {
  top: height,
  bottom: height,
  left: width,
  right: width,
};

export default class RecordButton extends Component {
  static defaultProps = {
    onPressIn: () => {},
    onPressOut: () => {},
  };

  state = {
    pressed: false,
  };

  onPressIn = (...args) => {
    this.setState({ pressed: true });
    this.props.onPressIn(...args);
  };

  onPressOut = (...args) => {
    this.setState({ pressed: false });
    this.props.onPressOut(...args);
  };

  render() {
    return (
      <TouchableWithoutFeedback
        {...this.props}
        onPressIn={this.onPressIn}
        onPressOut={this.onPressOut}
        hitSlop={this.state.pressed ? hitSlop : {}}
      >
        <View style={[this.props.style, styles.view]}>
          <AnimatedCircularProgress
            size={80}
            width={10}
            rotation={0}
            fill={this.props.progress}
            tintColor="red"
            backgroundColor="#FFF"
          />
        </View>
      </TouchableWithoutFeedback>
    );
  }
}

const styles = StyleSheet.create({
  container: {},
  view: {
    backgroundColor: 'transparent',
  },
});
