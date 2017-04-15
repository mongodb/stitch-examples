import React, { Component } from 'react';
import {
  StyleSheet,
  View,
  Text,
  TextInput,
  TouchableWithoutFeedback,
} from 'react-native';
import { inject } from 'mobx-react/native';

@inject('groupStore')
export default class NewGroup extends Component {
  state = { text: '' };

  createGroup = async () => {
    const { text } = this.state;
    if (!text || this.isUploading) {
      return;
    }
    this.isUploading = true;
    await this.props.groupStore.createGroup({ name: text });
    this.props.onClose();
  };
  render() {
    const hasText = this.state.text !== '';

    return (
      <View style={[styles.container, this.props.style]}>
        <View style={styles.header}>
          <Text style={styles.headerText}>New Group</Text>
        </View>
        <TextInput
          style={styles.textInput}
          onChangeText={text => this.setState({ text })}
          value={this.state.text}
          autoFocus
          placeholder="Group Name"
        />
        <TouchableWithoutFeedback onPress={this.props.onClose}>
          <View style={styles.topLeft}>
            <Text style={styles.buttonText}>Cancel</Text>
          </View>
        </TouchableWithoutFeedback>
        {hasText &&
          <TouchableWithoutFeedback onPress={this.createGroup}>
            <View style={styles.topRight}>
              <Text style={styles.buttonText}>Create</Text>
            </View>
          </TouchableWithoutFeedback>}
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'transparent',
    borderBottomColor: '#DDD',
    borderBottomWidth: 1,
  },
  header: {
    paddingTop: 40,
    paddingBottom: 10,
    marginBottom: 10,
    backgroundColor: '#50E3C2',
  },
  headerText: {
    color: '#FFF',
    textAlign: 'center',
    fontSize: 20,
  },
  topLeft: {
    position: 'absolute',
    left: 20,
    top: 44,
  },
  topRight: {
    position: 'absolute',
    right: 20,
    top: 44,
  },
  textInput: {
    height: 40,
    marginLeft: 30,
    marginRight: 30,
    marginBottom: 10,
  },
  buttonText: {
    fontSize: 14,
    color: '#fff',
  },
});
