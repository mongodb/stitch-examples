import { configure } from '@kadira/storybook';
import { addDecorator } from '@kadira/storybook';
import { muiTheme } from 'storybook-addon-material-ui';

// Add material-ui context for all stories
addDecorator(muiTheme());

const req = require.context('../src/components', true, /.stories.js$/)

function loadStories() {
  req.keys().forEach((filename) => req(filename))
}


configure(loadStories, module);