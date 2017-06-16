webpack = require('webpack')
module.exports = {
  entry: [
    './index.js'
  ],
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel'
      },
    ]
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  output: {
    path: "./dist",
    publicPath: '/static/',
    filename: 'bundle.js'
  },
  devServer: {
    contentBase: './dist',
    historyApiFallback: {
      index: 'index.html'
    }
  }
};

