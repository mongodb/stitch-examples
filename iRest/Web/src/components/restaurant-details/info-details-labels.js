import React from 'react';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';

const styles = {
  container: {},
  leftAndRight: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between'
  },
  title: {
    ...CommonStyles.textNormal,
    fontSize: '12px',
    opacity: 0.5,
    color: Colors.grey
  },
  value: {
    width: '185px',
    ...CommonStyles.divWithEllipsis,
    ...CommonStyles.textNormal,
    fontSize: '12px',
    textAlign: 'left',
    color: '#848484'
  },
  link: {
    width: '185px',
    ...CommonStyles.divWithEllipsis,
    ...CommonStyles.textNormal,
    fontSize: '12px',
    textDecoration: 'none',
    color: '#3b7adb',
    cursor: 'pointer'
  }
};

const AddressLabel = ({ address }) =>
  <div style={styles.leftAndRight}>
    <div style={styles.title}>{Localization.RESTAURANT_INFO.ADDRESS}</div>
    <div style={styles.value} title={address}>{address}</div>
  </div>;
const PhoneLabel = ({ phone }) =>
  <div style={styles.leftAndRight}>
    <div style={styles.title}>{Localization.RESTAURANT_INFO.PHONE}</div>
    <div style={styles.value}>{phone}</div>
  </div>;

const WebLabel = ({ web }) =>
  <div style={styles.leftAndRight}>
    <div style={styles.title}>{Localization.RESTAURANT_INFO.WEB}</div>
    <a style={styles.link} target="_blank" href={web}>
      {web.replace(/(^\w+:|^)\/\//, '')}
    </a>
  </div>;

const OpenLabel = ({ openHours }) =>
  <div style={styles.leftAndRight}>
    <div style={styles.title}>{Localization.RESTAURANT_INFO.OPEN_HOURS}</div>
    <div style={styles.value}>{openHours}</div>
  </div>;

const InfoDetailsLabel = ({ address, phone, web, openHours }) =>
  <div style={styles.container}>
    <AddressLabel address={address}/>
    <PhoneLabel phone={phone} />
    <WebLabel web={web} />
    <OpenLabel openHours={openHours} />
  </div>;

export default InfoDetailsLabel;
