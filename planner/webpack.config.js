webpack = require('webpack')
module.exports = {
  entry: [
    './src/index.js'
  ],
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        'NODE_ENV': JSON.stringify(process.env.NODE_ENV),
        'APP_NAME': JSON.stringify(process.env.APP_NAME),
        'BAAS_URL': JSON.stringify(process.env.BAAS_URL)
      }
    })
  ],
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel'
      }, 
      {
        test: /\.png$/,
        loader:"url-loader?limit=10000&mimetype=image/png"
      },
      {
        test: /\.svg$/,
        loader:"url-loader?limit=10000&mimetype=image/svg"
      },
      {
        test: /\.scss$/,
        loaders: ['style', 'css', 'resolve-url', 'sass?sourceMap']
      },
    ]
  },
  resolve: {
    extensions: ['', '.js', '.jsx']
  },
  output: {
    path: __dirname + '/dist',
    publicPath: '/',
    filename: 'bundle.js'
  },
  devServer: {
    contentBase: './dist',
    historyApiFallback: {
      index: '/index.html'
    }
  }
};

