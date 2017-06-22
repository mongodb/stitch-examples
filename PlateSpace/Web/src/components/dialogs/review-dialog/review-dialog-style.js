import { CommonStyles } from '../../../commons/common-styles/common-styles';

export const Styles = {
  container: {
    width: '473px',
    height: '470px',
    userSelect: 'none',
    cursor: 'default'
  },
  okButton: {
    ...CommonStyles.redElipseButton,
    marginRight: '70px',
    marginBottom: '50px',
    cursor: 'pointer'
  },
  dialogTitle: {
    ...CommonStyles.textNormal,
    fontSize: '26px',
    opacity: '0.5',
    textAlign: 'center'
  },
  rateTitle: {
    ...CommonStyles.textNormal,
    fontSize: '26px',
    opacity: '0.5',
    marginBottom: '22px'
  },
  input: {
    ...CommonStyles.textNormal,
    fontSize: '13px',
    alignItems: 'flex-start',
    width: '314px',
    height: '85px',
    opacity: '0.5',
    borderRadius: '10px',
    border: 'solid 1px #000000',
    outline: 'none',
    paddingLeft: '10px',
    paddingTop: '10px',
    marginBottom: '27px',
    resize: 'none'
  },
  dropZone: {
    height:'80px',
    width: '200px',
    borderWidth: '2px',
    borderColor: 'rgb(102, 102, 102)',
    borderStyle: 'dashed',
    borderRadius: '5px',
    fontSize: '14px'
  },
  dropZoneText: {
    fontSize: '14px',
    textAlign: 'center'
  }
};
