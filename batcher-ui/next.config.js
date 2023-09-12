/** @type {import('next').NextConfig} */

const config = require('./src/config/env.ts');

const env = process.env.ENV; // 'mainnet' | 'ghostnet'

console.info('🚀 Current env:', env);

const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: config[env],
  webpack: (config, { isServer, webpack }) => {
    console.log(isServer);
    if (!isServer) config.resolve.fallback['fs'] = false;

    return config;
  },
};

module.exports = nextConfig;
