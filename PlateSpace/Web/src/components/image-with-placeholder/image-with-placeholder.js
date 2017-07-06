import React from 'react';

const styles = {
  imgContainer: {
    backgroundColor: ' #fafafa',
    backgroundPosition: 'center',
    backgroundRepeat: 'no-repeat',
    display: 'flex',
    alignItems: 'center',
    userSelect: 'none'
  },
  image: {
    backgroundSize: 'cover',
    backgroundRepeat: 'no-repeat'
  }
};

const ImageWithPlaceholder = props =>
  <div
    style={{
      ...styles.imgContainer,
      ...props.style,
      backgroundImage: `url(${props.placeholder})`
    }}
  >
    <div
      style={{
        ...styles.image,
        ...props.imageStyle,
        backgroundImage: `url(${props.src})`
      }}
    />
  </div>;

ImageWithPlaceholder.propTypes = {
  placeholder: React.PropTypes.string.isRequired,
  src: React.PropTypes.string.isRequired
};

export default ImageWithPlaceholder;
