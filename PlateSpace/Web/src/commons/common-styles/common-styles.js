export const Colors = {
  white: '#fff',
  black: '#000',
  tomato: '#e64a19',
  deepBlue: '#4460a0',
  tomatoHover: '#ff612f',
  mangoYellow: '#fbc02d',
  pumpkinOrange: '#f57c00',
  grey: '#505050',
  lightGrey: '#f3f3f3',
  trueGreen: '#0a7e07'
};

const divWithEllipsis = {
  overflow: 'hidden',
  whiteSpace: 'nowrap',
  textOverflow: 'ellipsis'
};

const nonSelectable = {
  userSelect: 'none',
  cursor: 'default'
};

const textBold = {
  ...nonSelectable,
  fontFamily: 'Montserrat-Regular',
  fontWeight: 'bold',
  fontStyle: 'normal',
  fontStretch: 'normal',
  letterSpacing: 'normal',
  color: Colors.black
};

const textNormal = {
  ...nonSelectable,
  fontFamily: 'Montserrat-Light',
  fontWeight: 'normal',
  fontStyle: 'normal',
  fontStretch: 'normal',
  letterSpacing: 'normal',
  color: Colors.black
};

const elipseButton = {
  width: '320px',
  height: '40px',
  borderRadius: '38px 38px 38px 38px'
};

const redElipseButton = {
  ...elipseButton,
  ...textBold,
  backgroundColor: Colors.tomato,
  color: Colors.white,
  fontSize: '12px',
  ':hover': {
    backgroundColor: '#ff612f'
  },
  ':active': {
    backgroundColor: '#c7370a'
  }
};

const greenElipseButton = {
  ...elipseButton,
  ...textBold,
  backgroundColor: Colors.trueGreen,
  color: Colors.white,
  fontSize: '12px',
  ':hover': {
    backgroundColor: '#11950e'
  },
  ':active': {
    backgroundColor: '#055903'
  }
};

const blueElipseButton = {
  ...elipseButton,
  ...textBold,
  backgroundColor: Colors.deepBlue,
  fontSize: '12px',
  ':hover': {
    backgroundColor: '#5070b8'
  },
  ':active': {
    backgroundColor: '#243c73'
  }
};

const elipseInputStyle = {
  ...textBold,
  width: '298px',
  height: '40px',
  opacity: '0.5',
  borderRadius: '35px 35px 35px 35px',
  backgroundColor: Colors.white,
  border: 'solid 1px #000000',
  fontSize: '12px'
};

export const CommonStyles = {
  redElipseButton,
  greenElipseButton,
  blueElipseButton,
  elipseInputStyle,
  textBold,
  textNormal,
  divWithEllipsis
};
