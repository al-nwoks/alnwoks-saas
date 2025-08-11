const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

const isProd = process.env.NODE_ENV === 'production';

module.exports = {
  entry: {
    main: path.resolve(__dirname, './src/js/main.js'),
  },
  output: {
    filename: isProd ? 'js/bundle.[contenthash].js' : 'js/bundle.js',
    path: path.resolve(__dirname, 'dist'),
    publicPath: '/',
    clean: true,
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: ['@babel/preset-env'],
          },
        },
      },
      {
        test: /\.css$/i,
        use: [
          // In production, CSS is built via PostCSS into dist/css/main.css.
          // Keeping css-loader here only for potential future CSS-in-JS/modules.
          'style-loader',
          'css-loader',
          'postcss-loader',
        ],
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.resolve(__dirname, 'index.html'),
      filename: path.resolve(__dirname, 'dist/index.html'),
      inject: 'body',
      scriptLoading: 'defer',
      minify: isProd
        ? {
            removeComments: true,
            collapseWhitespace: true,
            removeRedundantAttributes: true,
            useShortDoctype: true,
            removeEmptyAttributes: true,
            removeStyleLinkTypeAttributes: true,
            keepClosingSlash: true,
            minifyJS: true,
            minifyCSS: false, // CSS is external via PostCSS
            minifyURLs: true,
          }
        : false,
    }),
  ],
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/](node_modules)[\\/]/,
          name: 'js/vendor',
          filename: isProd ? 'js/vendor.[contenthash].js' : 'js/vendor.js',
          enforce: true,
        },
      },
    },
    runtimeChunk: 'single',
  },
  resolve: {
    extensions: ['.js', '.json'],
  },
  devtool: isProd ? 'source-map' : 'eval-source-map',
  mode: isProd ? 'production' : 'development',
  infrastructureLogging: { level: 'warn' },
  stats: 'minimal',
};