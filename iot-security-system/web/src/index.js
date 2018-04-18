import React from 'react';
import ReactDOM from 'react-dom';
import { StitchClientFactory } from 'mongodb-stitch';


import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

async function startup() {
    let client = await StitchClientFactory.create('security-system-ukndi');
    if (client.authedId() == null) {
        await client.authenticate("google");
        return;
    }
    console.log(client.authedId());
    
    ReactDOM.render(<App client={client}/>, document.getElementById('root'));
    registerServiceWorker();
};

startup();


