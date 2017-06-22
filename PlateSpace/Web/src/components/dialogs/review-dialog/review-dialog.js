import React, { Component } from "react";
import Rate from "rc-rate";
import Dropzone from "react-dropzone";
import "rc-rate/assets/index.css";
import { StitchClient, builtins  } from "mongodb-stitch";

import { Localization } from "../../../localization";
import { Styles } from "./review-dialog-style";
import StyledDialog from "../styled-dialog";

const config = require("../../../config.js");

const stitchClient = new StitchClient(config.STITCH_APP_ID, {baseUrl: config.STITCH_ENDPOINT });

class ReviewDialog extends Component {
  constructor(props) {
    super(props);
    this.state = {
      rateValue: props.rateValue,
      reviewValue: props.reviewValue,
      imageUrlValue: props.imageUrlValue,
      clarifaiConceptsValue:props.imageConceptsValue
    };

    this.saveReview = this.saveReview.bind(this);
    this.rateValueChanged = this.rateValueChanged.bind(this);
    this.inputChanged = this.inputChanged.bind(this);
  }

  inputChanged() {
    this.setState({ reviewValue: this.reviewTextInput.value });
  }

  rateValueChanged(value) {
    this.setState({ rateValue: value });
  }

  componentWillReceiveProps(nextProps) {
    this.setState({
      rateValue: nextProps.rateValue,
      reviewValue: nextProps.reviewValue,
      imageUrlValue: nextProps.imageUrlValue
    });
  }

  saveReview() {
    if (!this.state.reviewValue && !this.state.rateValue) {
      alert(this.props.validationText);
      return;
    }
    this.props.onOkClick(
      this.state.rateValue,
      this.state.reviewValue,
      this.state.imageUrlValue,
      this.state.clarifaiConceptsValue,
      this.props.reviewId
    );
    this.setState({
      rateValue: this.props.rateValue,
      reviewValue: this.props.reviewValue,
      imageUrlValue: this.props.imageUrlValue
    });
  }

  onDrop(files) {

    const file = files[0];
    const reader = new FileReader();
    let imageUrl;
    //var x = this;
    reader.onload = (data) => {
      let fileKey = stitchClient.authedId() + "_" + Date.now().toString() + "_" + file.name;
      let fileData = btoa(data.target.result);
      let fileContentType = file.type;
      var filteredConcepts;
      
      const s3 = stitchClient.service('aws/s3', config.S3_SERVICE_NAME);
      const putPromise = stitchClient.executePipeline([
        builtins.binary('base64', fileData),
          s3.put(config.S3_BUCKET, fileKey, "public-read", fileContentType)]);
          
        putPromise.then(res => {
          console.log("AWS S3 url: ", res.result[0].location);
          imageUrl = res.result[0].location;
          this.setState({
            imageUrlValue: imageUrl
          });
          if(imageUrl) {
            stitchClient.executePipeline([builtins.namedPipeline('processImage', { imagePublicUrl: imageUrl })])
           .then(res => {
              console.log('clarifai result', res.result[0]);
              var clarifaiResult = res.result[0].bodyJSON;
              console.log('processImage pipeline result:', clarifaiResult);
              var concepts = clarifaiResult.outputs[0].data.concepts;
              console.log('Clarifai concepts before filtering:', concepts);
              
              concepts.forEach(function(concept) {
                if(concept.value > config.IMAGE_RECOGNITION_CONFIDENCE_THRESHOLD) {
                  if(!filteredConcepts) {
                    filteredConcepts = concept.name;
                  }
                  else {
                    filteredConcepts += ';' + concept.name;
                  }
                }
              }, this);
              console.log('Filtered Concepts', filteredConcepts);
              if(filteredConcepts && filteredConcepts.length > 0)
              this.setState({
                clarifaiConceptsValue: filteredConcepts
              });
            }).catch(err => {
          console.log("An error occurred in processImage pipeline: ", err);
            });      
          }    
        })
        .catch(err => {
          console.log("An error occurred in S3 Service: ", err);
        });
    };

    reader.readAsBinaryString(file);
  }

  render() {
    return (
      <StyledDialog
        open={this.props.open}
        title={this.props.title}
        buttonText={this.props.buttonText}
        onCancelClick={this.props.onCancelClick}
        onOkClick={this.saveReview}
        content={
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center"
            }}
          >
            <textarea
              maxLength={140}
              ref={reviewTextInput => (this.reviewTextInput = reviewTextInput)}
              onBlur={this.inputChanged}
              style={Styles.input}
              placeholder={Localization.REVIEW_DIALOG.INPUT_PLACEHOLDER}
              defaultValue={this.state.reviewValue}
            />
            <div style={Styles.rateTitle}>
              {Localization.REVIEW_DIALOG.RATE_TITLE}
            </div>
            <Rate
              defaultValue={this.state.rateValue}
              onChange={this.rateValueChanged}
              style={{ fontSize: 55 }}
            />
            
              {!this.state.imageUrlValue &&
              <div>
                <Dropzone style={Styles.dropZone}
                  multiple={false}
                  accept="image/png, image/jpg, image/jpeg"
                  onDrop={this.onDrop.bind(this)}
                >
                  <p style={Styles.dropZoneText}>
                    {Localization.REVIEW_DIALOG.IMAGE_UPLOAD_TEXT}
                  </p>
                </Dropzone>
              </div>}
              {this.state.imageUrlValue &&
              <div style={{alignItems:'center'}}>
                <div>
                <img src={this.state.imageUrlValue} title={this.state.clarifaiConceptsValue} alt={this.state.clarifaiConceptsValue} style={{width:'150px',textAlign:'center'}}/>
                </div>
              </div>             
                }
          </div>
        }
      />
    );
  }
}

ReviewDialog.propTypes = {
  open: React.PropTypes.bool.isRequired,
  title: React.PropTypes.string,
  buttonText: React.PropTypes.string,
  onCancelClick: React.PropTypes.func.isRequired,
  onOkClick: React.PropTypes.func.isRequired,
  rateValue: React.PropTypes.number,
  reviewValue: React.PropTypes.string,
  validationText: React.PropTypes.string.isRequired,
  imageUploadText: React.PropTypes.string.isRequired
};

ReviewDialog.defaultProps = {
  buttonText: "OK",
  title: "REVIEW DIALOG TITLE",
  rateValue: 0,
  reviewValue: ""
};

export default ReviewDialog;
