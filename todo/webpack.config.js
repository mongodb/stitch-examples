webpack = require('webpack')
module.exports = {
  entry: [
    'webpack-dev-server/client?http://0.0.0.0:8001', // WebpackDevServer host and port
    'webpack/hot/only-dev-server', // "only" prevents reload on syntax errors
    './src/index.js'
  ],
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify(process.env.NODE_ENV),
        'APP_ID': JSON.stringify(process.env.APP_ID),
        'STITCH_URL': JSON.stringify(process.env.STITCH_URL),
        'MONGODB_SERVICE': JSON.stringify(process.env.MONGODB_SERVICE)
      }
    })
  ],
  module: {
    loaders: [
    {
      test: /\.jsx?$/,
      exclude: /node_modules\/(?!(mongodb-extjson|bson))/,
      loader: 'babel-loader'
    },
    {
      test: /\.scss$/,
      loaders: ['style-loader', 'css-loader', 'resolve-url-loader', 'sass-loader?sourceMap']
    },
    ]
  },
  resolve: {
    extensions: ['.js', '.jsx']
  },
  output: {
    path: __dirname + '/' + process.env.DISTROOT + '/dist',
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

