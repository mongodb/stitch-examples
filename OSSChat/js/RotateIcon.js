import React, { Component } from 'react';
import { Animated, Easing } from 'react-native';
import Icon from 'react-native-vector-icons/Entypo';

const AnimatedIcon = Animated.createAnimatedComponent(Icon);

export default class RotateIcon extends Component {
  state = { spinValue: new Animated.Value(0) };

  componentDidMount() {
    this.shouldSpin(this.props);
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.rotate !== nextProps.rotate) {
      this.shouldSpin(nextProps);
    }
  }

  shouldSpin(props) {
    if (props.rotate) {
      this.spin();
    } else {
      this.state.spinValue.stopAnimation();
    }
  }

  spin = () => {
    this.state.spinValue.setValue(0);

    Animated.timing(this.state.spinValue, {
      toValue: 1,
      duration: 3000,
      easing: Easing.linear,
    }).start(this.spin);
  };

  render() {
    const spin = this.state.spinValue.interpolate({
      inputRange: [0, 1],
      outputRange: ['0deg', '360deg'],
    });
    const transform = { transform: [{ rotate: spin }] };

    return (
      <AnimatedIcon {...this.props} style={[this.props.style, transform]} />
    );
  }
}
