/**
 * Regroup all contracts hash needed to Batcher works properly
 * and provide functions to ensure all contracts hashes are setuped.
 */

const CONTRACTS_NAMES = [
  'batcher',
  'market_maker',
  'token_manager',
  'tzBTC_vault',
  'USDT_vault',
  'EURL_vault',
  'BTCtz_vault',
  'USDtz_vault',
];

const ghostnet = {
  batcher: 'KT1Lh5Wkf2dtgNR23DnrdGcG4igfXUc9HQFW',
  market_maker: 'KT1VpMZjKtPa2oEdD2tQJiV7Mj3r4xY4QKFQ',
  token_manager: 'KT1AwSv5yaew3ZEEPn7HkDMvnbCrLniTBWCM',
  tzBTC_vault: 'KT1QChZQRof4pYheGE5MbUBv3oBsdJiy1Ue3',
  USDT_vault: 'KT1J2mW59LADXgD6AvywT46KF1Hyep7pKYcL',
  USDtz_vault: 'KT1KftikTS3nffDMuUobjBHt6LHqe5Zb8xMw',
  BTCtz_vault: 'KT1BmMZD3GBEjMRnPEvyuC1ph57TRhoDdwLU',
  EURL_vault: 'KT1J66Yj44DaD2EtvSPgz1XjjU9gZPDHoiBb',
};

const mainnet = {
  batcher: 'KT1CoTu4CXcWoVk69Ukbgwx2iDK7ZA4FMSpJ',
  market_maker: 'KT1TNX1YLCmPJN4rbwAUsUAdnqVYrZ5X5YNB',
  token_manager: '',
  tzBTC_vault: '',
  USDT_vault: '',
  USDtz_vault: '',
  BTCtz_vault: '',
  EURL_vault: '',
};

const toEnvVar = contracts =>
  Object.entries(contracts)
    .map(([k, v]) => [`NEXT_PUBLIC_${k.toUpperCase()}_CONTRACT_HASH`, v])
    .reduce((acc, current) => ({ ...acc, [current[0]]: current[1] }), {});

const isContractsWellConfigured = contracts => {
  return CONTRACTS_NAMES.every(name => Object.keys(contracts).includes(name));
};

module.exports = {
  ghostnet,
  mainnet,
  toEnvVar,
  isContractsWellConfigured,
};
