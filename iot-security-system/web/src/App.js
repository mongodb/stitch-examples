import React, { Component } from 'react';
import Webcam from 'react-webcam';

import './App.css';

class WebcamCapture extends React.Component {
    constructor(props) {
        super(props);
        console.log(props);
    }
    
    setRef = (webcam) => {
        this.webcam = webcam;
    }

    capture = () => {
        const imageSrc = this.webcam.getScreenshot();
        this.props.stopCapture(imageSrc);
    };

    render() {
        if (!this.props.active) {
            return "";
        }
        
        return (
            <div>
                <Webcam
                    audio={false}
                    height={350}
                    ref={this.setRef}
                    screenshotFormat="image/jpeg"
                    width={350}
                />
                <button onClick={this.capture}>Capture photo</button>
            </div>
        );
    }
}


class App extends Component {
    constructor(props) {
        super(props)
        this.client = props.client;
        this.db = this.client.service('mongodb', 'mongodb-atlas').db('security-system');
        
        this.state = { doCapture : false, images : [] };

        this.startCapture = this.startCapture.bind(this);
        this.stopCapture = this.stopCapture.bind(this);
        this.loadImages = this.loadImages.bind(this);

        this.loadImages();
    }

    startCapture() {
        this.setState( { doCapture : true } );
    }

    stopCapture(imageSrc) {
        this.setState( { doCapture : false } );
        this.db.collection("images").insertOne( { owner_id : this.client.authedId(), image : imageSrc } ).then( this.loadImages );
    }

    loadImages() {
        this.db.collection("images").find( {} ).execute().then( imageDocs => {
            this.setState( { images : imageDocs.map( doc => { return doc; } ) } );
        } );
    }
    
    render() {
        const images = this.state.images.map( function(img) {
            return <div key={img._id}>
                <img src={img.image}/>
            </div>;
        } );
        
        return (
            <div className="App">
                <header className="App-header">
                    <h1 className="App-title">My Security System</h1>
                </header>
                {images}
                <button onClick={this.startCapture}>Add new picture</button>
                <WebcamCapture active={this.state.doCapture} stopCapture={this.stopCapture}/>
            </div>
        );
    }
}

export default App;
