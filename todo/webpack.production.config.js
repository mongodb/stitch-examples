 webpack = require('webpack')
 module.exports = {
   entry: [
     './src/index.js'
   ],
   plugins: [
     new webpack.DefinePlugin({
       'process.env': {
         'GIT_REV': JSON.stringify(process.env.GIT_REV)
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
       {test: /\.svg/, loader: 'svg-url-loader'},
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
     path: __dirname + '/dist/static',
     publicPath: '/',
     filename: 'bundle.js'
   },
   devtool: "cheap-source-map",
 };
