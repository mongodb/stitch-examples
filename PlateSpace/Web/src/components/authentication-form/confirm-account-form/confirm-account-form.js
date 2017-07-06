import React, { Component } from 'react';
import {
  CommonStyles,
  Colors
} from "../../../commons/common-styles/common-styles";
import CustomButton from "../../custom-button";

const styles = {
  container: {
    display: "flex",
    flexDirection: "column",
    width: "618px",
    height: "590px",
    alignItems: "center",
    borderRadius: "10px",
    background: "#fff",
    userSelect: "none",
    cursor: "default"
  },
  title: {
    ...CommonStyles.textNormal,
    width: "335px",
    height: "48px",
    opacity: "0.5",
    fontSize: "26px",
    textAlign: "center",
    color: Colors.black,
    marginBottom: "20px",
    marginTop: "20px"
  },
  skipButton: {
    width: "144px",
    height: "35px",
    margin: 0,
    marginBottom: "20px"
  },
  skipLabelButton: {
    ...CommonStyles.textBold,
    cursor: "pointer",
    fontSize: "12px",
    opacity: 0.5
  }
};

class ConfirmAccountForm extends Component {
  constructor(props) {
    super(props);

    this.confirmAccountClicked = this.confirmAccountClicked.bind(this);
  }

  confirmAccountClicked() {
    this.props.onConfirmClick();
  }
  
  render() {
    return (
      <div style={styles.emailPasswordContainer}>
        <CustomButton
          style={CommonStyles.redElipseButton}
          onClick={this.confirmAccountClicked}
          label={this.props.confirmButtonText}
        />
      </div>
    );
  }
}

ConfirmAccountForm.propTypes = {
  onConfirmClick: React.PropTypes.func.isRequired
};

export default ConfirmAccountForm;
