/** @type {import('next').NextConfig} */

const config = require('./config/env.ts');

const env = process.env.ENV; // 'mainnet' | 'ghostnet'
console.log('🚀 ~ file: next.config.js:6 ~ env:', env);

const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: config[env],
  // webpack: (config, { isServer, webpack }) => {
  //   console.log(isServer);
  //   if (!isServer) config.resolve.fallback['fs'] = false;

  //   const fallback = config.resolve.fallback || {};
  //   Object.assign(fallback, {
  //     crypto: require.resolve('crypto-browserify'),
  //     stream: require.resolve('stream-browserify'),
  //     assert: require.resolve('assert'),
  //     http: require.resolve('stream-http'),
  //     https: require.resolve('https-browserify'),
  //     os: require.resolve('os-browserify'),
  //     url: require.resolve('url'),
  //   });
  //   config.resolve.fallback = fallback;
  //   config.plugins = (config.plugins || []).concat([
  //     new webpack.ProvidePlugin({
  //       process: 'process/browser',
  //       Buffer: ['buffer', 'Buffer'],
  //     }),
  //   ]);
  //   return config;
  // },
};

module.exports = nextConfig;
