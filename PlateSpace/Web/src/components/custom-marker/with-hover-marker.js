import React, { Component } from 'react';
import hoverPin from '../../assets/images/ic-location-hover.png';
import normalPin from '../../assets/images/ic-location-normal.png';
import BubbleDetails from '../bubble-details/bubble-details';
import HoverWrapper from '../hover-wrapper';

const styles = {
  bubbleStyle: {
    position: 'absolute',
    top: '-85px',
    left: '-92px',
    zIndex: 1,
    cursor: 'poiner'
  },
  img: {
    userSelect: 'none',
    cursor: 'poiner'
  }
};

const NormalMarker = props =>
  <img style={styles.img} alt="marker" src={normalPin} />;

const MarkerWithBubble = props =>
  <div onClick={() => props.onClick(props.id)}>
    <BubbleDetails {...props} style={styles.bubbleStyle} />
    <img style={styles.img} alt="marker" src={hoverPin} />
  </div>;

export default class WithHoverMarker extends Component {
  constructor(props) {
    super(props);

    this.state = {
      hover: false
    };

    this.turnOff = this.turnOff.bind(this);
    this.turnOn = this.turnOn.bind(this);
  }

  turnOn() {
    this.setState({ hover: true });
  }

  turnOff() {
    this.setState({ hover: false });
  }

  render() {
    return this.props.$hover || this.state.hover
      ? <HoverWrapper turnOff={this.turnOff} turnOn={this.turnOn}>
          <MarkerWithBubble {...this.props} />
        </HoverWrapper>
      : <NormalMarker />;
  }
}
