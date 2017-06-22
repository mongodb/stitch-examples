import React from 'react';
import Rate from 'rc-rate';
import 'rc-rate/assets/index.css';
import dateFns from 'date-fns';

import {
  CommonStyles,
  Colors
} from '../../commons/common-styles/common-styles';
import { Localization } from '../../localization';
import EditButton from '../custom-button';

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
  },
  thumbnailContainer: {
    marginRight:'5px'
  },
  thumbnailImage: {
    width:'50px', borderRadius:'3px'
  },
  imageDescription: {
    position: 'absolute',
  top: '0',
  bottom: '0',
  left: '0',
  right: '0',
  background: 'rgba(29, 106, 154, 0.72)',
  color: '#fff',
  visibility: 'hidden',
  opacity: '0',
  /* transition effect. not necessary */
  transition: 'opacity .2s, visibility .2s'
  },
};

const ThumbnailContainer = props =>
  <div style={styles.thumbnailContainer}>
    <a href={props.imageUrl} target='_blank' alt={props.imageRecognitionData}>
      <img style={styles.thumbnailImage} src={props.imageUrl} alt={props.imageRecognitionData} title={props.imageRecognitionData} ></img>
      <p style={styles.imageDescription}>{props.imageRecognitionData}</p>
      </a>
  </div>;

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
      <EditButton
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
    <div style={{display:'flex'}}>
    {props.imageUrl &&
    <ThumbnailContainer {...props} />}
    <ReviewText text={props.text} />
    </div>
  </div>;

ReviewItem.propTypes = {
  name: React.PropTypes.string.isRequired,
  rateValue: React.PropTypes.number,
  date: React.PropTypes.instanceOf(Date).isRequired,
  text: React.PropTypes.string.isRequired,
  imageUrl: React.PropTypes.string,
  imageRecognitionData: React.PropTypes.string,
  editable: React.PropTypes.bool,
  editClick: React.PropTypes.func
};

export default ReviewItem;
