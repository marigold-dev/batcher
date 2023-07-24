/** @type {import('next').NextConfig} */

const config = require('./config/env.ts');

const env = process.env.ENV; // 'mainnet' | 'ghostnet'

const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: config[env],
};

module.exports = nextConfig;
