/** @type {import('next').NextConfig} */

const config = require('./config/env.ts');

const env = process.env.ENV; // 'mainnet' | 'ghostnet'

const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: config[env],
  webpack: (config, { isServer }) => {
    console.log(isServer);
    if (!isServer) config.resolve.fallback['fs'] = false;
    return config;
  },
};

module.exports = nextConfig;
