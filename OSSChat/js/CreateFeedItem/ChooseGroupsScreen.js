import React, { Component } from 'react';
import {
  ScrollView,
  StyleSheet,
  View,
  Text,
  Modal,
  TouchableHighlight,
  TouchableWithoutFeedback,
} from 'react-native';
import Icon from 'react-native-vector-icons/FontAwesome';
import LinearGradient from 'react-native-linear-gradient'; // eslint-disable-line
import { observer, inject } from 'mobx-react/native';
import CreateNewGroup from './CreateNewGroup';

@inject('groupStore', 'uploader')
@observer
export default class ChooseGroupsScreen extends Component {
  state = {
    showNewGroup: false,
  };

  toggleNewGroup = () =>
    this.setState({ showNewGroup: !this.state.showNewGroup });

  upload = async () => {
    const { hasSelectedGroups } = this.props.uploader.localAsset;
    if (!hasSelectedGroups || this.props.uploader.uploading) {
      return;
    }

    await this.props.uploader.upload();
  };

  renderRow = rowData => {
    const isSelected = this.props.uploader.localAsset.groups.has(rowData.id);
    return (
      <TouchableHighlight
        key={rowData.id}
        onPress={() => this.props.uploader.toggleGroup({ id: rowData.id })}
        underlayColor="#DDD"
      >
        <View style={styles.row}>
          <Text style={styles.text}>
            {rowData.name}
          </Text>
          <Icon
            name={isSelected ? 'check-circle' : 'circle-thin'}
            color={isSelected ? '#FF246B' : '#BBB'}
            size={25}
            style={styles.rowIcon}
          />
        </View>
      </TouchableHighlight>
    );
  };

  render() {
    const { hasSelectedGroups } = this.props.uploader.localAsset;
    const { uploading } = this.props.uploader;
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerText}>Send to Groups</Text>
        </View>
        <ScrollView style={styles.listView}>
          {this.props.groupStore.groups.map(this.renderRow)}
        </ScrollView>
        <Icon
          name="angle-left"
          color="white"
          size={30}
          style={styles.goBack}
          onPress={this.props.goBack}
        />
        <TouchableWithoutFeedback onPress={this.toggleNewGroup}>
          <View style={styles.newGroup}>
            <Text style={styles.buttonText}>New Group</Text>
          </View>
        </TouchableWithoutFeedback>
        <TouchableWithoutFeedback onPress={this.upload}>
          <LinearGradient
            start={{ x: 0, y: 0.5 }}
            end={{ x: 0.75, y: 0.5 }}
            colors={
              hasSelectedGroups ? ['#EB729D', '#FF246B'] : ['#bbb', '#bbb']
            }
            style={styles.submitWrapper}
          >
            <Text style={styles.submitWrapperText}>
              {uploading ? 'Uploading...' : 'Send'}
            </Text>
          </LinearGradient>
        </TouchableWithoutFeedback>
        <Modal
          animationType="fade"
          transparent={false}
          visible={this.state.showNewGroup}
          onRequestClose={this.toggleNewGroup}
        >
          <CreateNewGroup onClose={this.toggleNewGroup} />
        </Modal>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1 },
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
  goBack: {
    position: 'absolute',
    left: 20,
    top: 37,
  },
  newGroup: {
    position: 'absolute',
    right: 20,
    top: 45,
  },
  upload: {
    position: 'absolute',
    right: 30,
    bottom: 20,
  },
  listView: { flex: 1 },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 10,
    paddingLeft: 30,
  },
  rowIcon: {
    marginRight: 30,
  },
  submitWrapper: {
    flex: 0,
    justifyContent: 'center',
    alignItems: 'center',
    height: 55,
    paddingLeft: 15,
    paddingRight: 15,
  },
  submitWrapperText: {
    fontSize: 18,
    fontFamily: 'Gill Sans',
    margin: 10,
    color: '#ffffff',
    backgroundColor: 'transparent',
  },
  createNewGroup: {
    position: 'absolute',
    top: 60,
    left: 20,
    width: 300,
    height: 150,
  },
  buttonText: {
    fontSize: 14,
    color: '#fff',
  },
});
