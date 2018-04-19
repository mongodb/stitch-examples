import React from 'react';
import ReactDOM from 'react-dom';
import { StitchClientFactory } from 'mongodb-stitch';

import './index.css';
import App from './App';
import registerServiceWorker from './registerServiceWorker';

async function startup() {
    let client = await StitchClientFactory.create('<YOUR STITCH APP ID>');
    if (client.authedId() == null) {
        await client.authenticate('google');
        return;
    }

    ReactDOM.render(<App client={client} />, document.getElementById('root'));
    registerServiceWorker();
}

startup();
