/** @type {import('next').NextConfig} */

const config = require('./config/env.js');

// 'mainnet' | 'ghostnet'
const env = process.env.ENV;
console.log(config[env]);
const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: config[env],
  webpack: (config, options) => {
    config.module.rules.push({
      test: /\.less$/i,
      use: [
        // compiles Less to CSS
        'style-loader',
        'css-loader',
        {
          loader: 'less-loader',
          options: {
            lessOptions: { javascriptEnabled: true },
          },
        },
      ],
    });

    return config;
  },
};

module.exports = nextConfig;
