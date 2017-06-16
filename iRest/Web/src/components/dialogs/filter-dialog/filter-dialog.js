import React, { Component } from 'react';

import { Localization } from '../../../localization';
import FilterList from '../../filter-list';
import StyledDialog from '../styled-dialog';

const FilterListContainer = props =>
  <div
    style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}
  >
    <FilterList filterChanged={props.filterChanged} filters={props.filters} />
  </div>;

export default class FilterDialog extends Component {
  constructor(props) {
    super(props);
    this.state = {
      filterList: props.filters
    };

    this.saveFilters = this.saveFilters.bind(this);
    this.filterChanged = this.filterChanged.bind(this);
  }

  componentWillReceiveProps(nextProps) {
    this.setState({
      filterList: nextProps.filters
    });
  }

  saveFilters() {
    this.props.saveFilters(this.state.filterList);
  }

  filterChanged(filterId) {
    const { filterList } = this.state;
    const toggle = filter => ({ ...filter, toggled: !filter.toggled });
    const filters = filterList.map(
      filter => (filter.id === filterId ? toggle(filter) : filter)
    );
    this.setState({ filterList: filters });
  }

  render() {
    return (
      <StyledDialog
        title={Localization.FILTER_DIALOG.TITLE}
        onCancelClick={this.props.onCancelClick}
        buttonText={Localization.FILTER_DIALOG.OK_BUTTON_TEXT}
        open={this.props.open}
        onOkClick={this.saveFilters}
        content={
          <FilterListContainer
            filterChanged={this.filterChanged}
            filters={this.state.filterList}
          />
        }
      />
    );
  }
}

FilterDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  onCancelClick: React.PropTypes.func.isRequired,
  filters: React.PropTypes.array.isRequired,
  saveFilters: React.PropTypes.func.isRequired
};
