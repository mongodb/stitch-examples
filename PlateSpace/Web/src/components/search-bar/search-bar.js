import React, { Component } from 'react';

import { Localization } from '../../localization';
import searchIcon from '../../assets/images/ic-search.png';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import CustomButton from '../custom-button';

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'row',
    width: '618px',
    height: '45px',
    userSelect: 'none',
    cursor: 'default'
  },
  input: {
    width: '500px',
    height: '43px',
    ...CommonStyles.textBold,
    border: '0px',
    fontSize: '12px',
    backgroundColor: Colors.white,
    borderTopLeftRadius: '35px',
    borderBottomLeftRadius: '35px',
    paddingLeft: '54px',
    outline: 'none',
    letterSpacing: '1px',
    userSelect: 'none',
    cursor: 'default'
  },
  button: {
    ...CommonStyles.redElipseButton,
    width: '118px',
    height: '45px',
    borderRadius: '0px 35px 35px 0px',
    alignItems: 'center',
    backgroundColor: Colors.tomato,
    display: 'flex',
    userSelect: 'none',
    cursor: 'pointer'
  },
  buttonText: {
    ...CommonStyles.textBold,
    color: Colors.white,
    fontSize: '12px',
    letterSpacing: '1.5px',
    cursor: 'pointer'
  },
  searchIcon: {
    position: 'absolute',
    paddingLeft: '24px',
    paddingTop: '12px'
  }
};

export default class SearchBar extends Component {
  constructor(props) {
    super(props);

    this.searchClicked = this.searchClicked.bind(this);
    this.handleKeyUp = this.handleKeyUp.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.defaultValue !== this.props.defaultValue) {
      this.input.value = nextProps.defaultValue;
    }
  }

  searchClicked() {
    this.props.searchClicked(this.input.value);
  }

  handleKeyUp(e) {
    if (e.keyCode === 13) {
      this.searchClicked();
    }
  }

  render() {
    return (
      <div style={styles.container}>
        <img style={styles.searchIcon} src={searchIcon} alt="search icon" />
        <input
          ref={input => (this.input = input)}
          onKeyUp={this.handleKeyUp}
          style={styles.input}
          placeholder={this.props.inputPlaceholder}
          defaultValue={this.props.defaultValue}
        />
        <CustomButton
          onClick={this.searchClicked}
          style={styles.button}
          labelStyle={styles.buttonText}
          label={this.props.buttonText}
        />
      </div>
    );
  }
}

SearchBar.propTypes = {
  inputPlaceholder: React.PropTypes.string,
  buttonText: React.PropTypes.string,
  searchClicked: React.PropTypes.func.isRequired
};

SearchBar.defaultProps = {
  inputPlaceholder: Localization.SEARCH_COMPONENT.INPUT_PLACEHOLDER,
  buttonText: Localization.SEARCH_COMPONENT.BUTTON_TEXT
};
