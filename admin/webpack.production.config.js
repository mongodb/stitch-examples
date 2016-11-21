webpack = require('Webpack')
module.exports = {
  entry: [
    './src/index.js'
  ],
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify('production')
      }
    })
  ],
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loaders: ['babel']
      }, 
      {
        test: /\.png$/,
        loader:"url-loader?limit=10000&mimetype=image/png"
      },
      {
        test: /\.scss$/,
        loaders: ['style', 'css', 'resolve-url', 'sass']
      },
    ]
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  output: {
    path: __dirname + '/prod/dist',
    publicPath: '/',
    filename: 'bundle.js'
  },
  devtool: "cheap-source-map",
};

