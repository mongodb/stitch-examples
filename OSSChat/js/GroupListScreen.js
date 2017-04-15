import React, { Component } from 'react';
import {
  ListView,
  RefreshControl,
  Modal,
  StyleSheet,
  View,
  RecyclerViewBackedScrollView,
  Text,
  TouchableHighlight,
} from 'react-native';
import { observer, inject } from 'mobx-react/native';
import GroupViewerScreen from './GroupViewerScreen';

@inject('groupStore', 'nativeStore')
@observer
export default class GroupListScreen extends Component {
  state = {
    showGroup: false,
    activeGroup: {},
  };

  showGroup(group) {
    this.setState({ showGroup: true, activeGroup: group });
  }

  closeGroup = () => {
    this.setState({ showGroup: false, activeGroup: {} });
  };

  renderRow = group => (
    <TouchableHighlight
      onPress={() => this.showGroup(group)}
      underlayColor="#DDD"
    >
      <View>
        <View style={styles.row}>
          <Text style={styles.rowText}>
            {group.name}
          </Text>
          <View style={styles.rowTextCountWrapper}>
            <Text style={styles.rowTextCount}>
              {group.feedItems.length}
            </Text>
          </View>
        </View>
      </View>
    </TouchableHighlight>
  );

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.headerText}>
            Groups
          </Text>
        </View>
        <ListView
          enableEmptySections
          dataSource={this.props.nativeStore.groupDataSource}
          renderRow={this.renderRow}
          renderScrollComponent={props => (
            <RecyclerViewBackedScrollView {...props} />
          )}
          refreshControl={
            (
              <RefreshControl
                refreshing={this.props.groupStore.loading}
                onRefresh={this.props.groupStore.load}
              />
            )
          }
        />
        <Modal
          animationType="fade"
          transparent={false}
          visible={this.state.showGroup}
          onRequestClose={this.closeGroup}
        >
          <GroupViewerScreen
            close={this.closeGroup}
            group={this.state.activeGroup}
          />
        </Modal>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#EEE' },
  header: {
    paddingTop: 40,
    paddingBottom: 10,
    marginBottom: 10,
    backgroundColor: '#b664ff',
  },
  headerText: {
    color: 'white',
    textAlign: 'center',
    fontSize: 20,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 15,
    paddingBottom: 15,
    paddingLeft: 30,
    paddingRight: 30,
  },
  rowText: {
    // color: 'white',
  },
  rowTextCountWrapper: {
    backgroundColor: '#FBB10F',
    padding: 4,
    borderRadius: 4,
  },
  rowTextCount: {
    fontSize: 10,
    color: 'white',
    fontWeight: 'bold',
  },
});
