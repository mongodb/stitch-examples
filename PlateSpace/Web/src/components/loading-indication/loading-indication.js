import React from 'react';
import CircularProgress from 'material-ui/CircularProgress';
import { Colors } from '../../commons/common-styles/common-styles';

const LoadingIndication = props =>
  <div
    style={{
      width: '100vh',
      height: '100vh',
      display: 'flex',
      justifyContent: 'center'
    }}
  >
    <CircularProgress
      color={Colors.grey}
      style={{ marginTop: '200px' }}
      size={100}
      thickness={7}
    />
  </div>;

export default LoadingIndication;
