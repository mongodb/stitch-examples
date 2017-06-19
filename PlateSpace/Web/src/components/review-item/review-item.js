import React from 'react';
import Rate from 'rc-rate';
import 'rc-rate/assets/index.css';
import dateFns from 'date-fns';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import Custombuttom from '../custom-button';

const styles = {
  container: {
    width: '556px',
    marginBottom: '20px'
  },
  titleContainer: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'baseline'
  },
  headerContainer: {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'baseline',
    justifyContent: 'space-between',
    marginBottom: '11px'
  },
  name: {
    ...CommonStyles.textBold,
    ...CommonStyles.divWithEllipsis,
    fontSize: '14px',
    width: '215px'
  },
  stars: {
    fontSize: '17px',
    userSelect: 'none',
    marginLeft: '20px'
  },
  date: {
    ...CommonStyles.textNormal,
    fontSize: '12px',
    color: Colors.grey,
    opacity: 0.4
  },
  text: {
    ...CommonStyles.textNormal,
    fontSize: '13px',
    color: Colors.grey,
    opacity: 0.7,
    wordWrap: 'break-word'
  },
  button: {
    width: '57px',
    marginLeft: '20px',
    height: '22px',
    borderRadius: '45px',
    border: 'solid 1px #0a7e07',
    textAlign: 'center',
    cursor: 'pointer'
  },
  buttonLabel: {
    ...CommonStyles.textBold,
    color: Colors.trueGreen,
    fontSize: '10px',
    letterSpacing: '0px',
    fontStrech: 'normal',
    cursor: 'pointer'
  }
};

const NameRateContainer = props =>
  <div style={styles.titleContainer}>
    <div style={styles.name}>{props.name}</div>
    <Rate
      disabled
      value={Number(props.rateValue)}
      allowHalf={true}
      style={styles.stars}
    />
    {props.editable &&
      <Custombuttom
        onClick={() => props.editClick(props.id)}
        style={styles.button}
        labelStyle={styles.buttonLabel}
        label={Localization.REVIEW_ITEM.EDIT_BUTTON_TEXT}
      />}
  </div>;

const Header = props =>
  <div style={styles.headerContainer}>
    <NameRateContainer {...props} />
    <div style={styles.date}>{dateFns.format(props.date, 'DD MMMM YYYY')}</div>
  </div>;

const ReviewText = props => <div style={styles.text}>{props.text}</div>;

const ReviewItem = props =>
  <div style={styles.container}>
    <Header {...props} />
    <ReviewText text={props.text} />
  </div>;

ReviewItem.propTypes = {
  name: React.PropTypes.string.isRequired,
  rateValue: React.PropTypes.number,
  date: React.PropTypes.instanceOf(Date).isRequired,
  text: React.PropTypes.string.isRequired,
  editable: React.PropTypes.bool,
  editClick: React.PropTypes.func
};

export default ReviewItem;
