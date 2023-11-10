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
  batcher: 'KT1GSDzo6PU8i732m8WuY9XcTyxiGRaYBsv2',
  market_maker: 'KT1T4dbnaNKpGLV89R6drrupy5HVE74bQE3r',
  token_manager: 'KT1HLQ4kk4nUjXxBBR4PE3sAQzv4fHRMoBGD',
  tzBTC_vault: 'KT1Jr5jTm2VG9eyosoqZwZYuN95PjUpysNyS',
  USDT_vault: 'KT1A2uq9zMgXGJGhXRiHvUa8PGEKMn9dyyJN',
  USDtz_vault: 'KT1CRgudfxt4sqdqZtFEGJpJxZrJ6LtSY5Yp',
  BTCtz_vault: 'KT1HV7xrS8nvNfWt4ANLfVCBhACRzHKb2nEa',
  EURL_vault: 'KT1Gy8BPpJdAR6ZwgBaVeXrMW2pyX2NL8LSp',
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
