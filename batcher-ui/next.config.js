/** @type {import('next').NextConfig} */


const env = process.env.ENV; // 'mainnet' | 'ghostnet'

const config = require('./src/config/env.js');
const contractsConfig = require('./src/config/contracts.js');

const contractHashes = contractsConfig[env];
const envConfig = config[env];

if (
  !contractHashes ||
  !contractsConfig.isContractsWellConfigured(contractHashes)
) {
  throw new Error(
    'Configuration error on contracts hashes. Please check in src/config/contracts.js file.'
  );
}

if (!envConfig || !config.isConfigOK(envConfig)) {
  throw new Error(
    'Configuration error on environment variables. Please check in src/config/env.js file.'
  );
}

console.info('🚀 Current env:', env);

const nextConfig = {
  reactStrictMode: false,
  swcMinify: true,
  env: {
    ...config.toEnvVar(envConfig),
    ...contractsConfig.toEnvVar(contractHashes),
  },
  webpack: (config, { isServer, webpack }) => {
    if (!isServer) config.resolve.fallback['fs'] = false;

    return config;
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'ipfs.io',
      },
    ],
  },
};

module.exports = nextConfig;
