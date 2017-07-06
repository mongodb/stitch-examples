import React from 'react';
import { withRouter } from 'react-router';

import '../../assets/fonts/fonts.css';
import bgImage from '../../assets/images/header-image.png';
import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import FiltersLabels from '../filters-labels';
import { Localization } from '../../localization';
import SearchBar from '../search-bar';

const styles = {
  container: {
    width: '100%',
    height: '213px',
    backgroundSize: 'cover',
    userSelect: 'none',
    cursor: 'default',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundImage: `url(${bgImage})`,
    backgroundRepeat: 'no-repeat'
  },
  childrenContainer: {
    display: 'flex',
    flexDirection: 'column'
  },
  titleContainer: {
    display: 'flex',
    alignItems: 'baseline',
    alignSelf: 'flex-start',
    flexDirection: 'row',
    userSelect: 'none',
    cursor: 'default'
  },
  title: {
    ...CommonStyles.textBold,
    fontSize: '40px',
    height: '40px',
    color: Colors.white,
    cursor: 'inherit'
  },
  subTitle: {
    ...CommonStyles.textNormal,
    height: '40px',
    fontSize: '16px',
    color: Colors.white,
    opacity: 0.7,
    marginLeft: '30px',
    cursor: 'inherit'
  },
  bottomComponent: {
    marginTop: '30px'
  },
  logOut: {
    ...CommonStyles.textNormal,
    color: Colors.white,
    fontSize: '12px',
    cursor: 'pointer'
  }
};

const shouldRedirect = router => {
  const hasQuery =
    router.location.query &&
    (router.location.query.name || router.location.query.attributes);

  return !router.isActive({ pathname: '/restaurants' }) || hasQuery;
};

const redirectToMain = router => {
  if (shouldRedirect(router)) {
    router.push('/restaurants');
  }
};

const Header = props =>
  <div style={styles.container}>
    <div style={styles.childrenContainer}>
      <div style={{ display: 'flex', justifyContent: 'space-between' }}>
        <div
          style={{
            ...styles.titleContainer,
            ...{ cursor: shouldRedirect(props.router) ? 'pointer' : 'default' }
          }}
          onClick={() => redirectToMain(props.router)}
        >
          <div style={styles.title}>{props.title}</div>
          <div style={styles.subTitle}>{props.subTitle}</div>
        </div>
        <div style={styles.logOut} onClick={props.logoutClicked}>
          {Localization.HEADER.LOG_OUT}
        </div>
      </div>
      <SearchBar
        defaultValue={props.searchDefaultValue}
        searchClicked={props.searchClicked}
      />
      <div style={styles.bottomComponent}>
        <FiltersLabels
          editButtonClicked={props.editButtonClicked}
          title={Localization.HEADER.FILTER_TITLE}
          filters={props.filters.filter(item => item.toggled)}
        />
      </div>
    </div>
  </div>;

export default withRouter(Header);
