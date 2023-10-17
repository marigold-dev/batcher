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
  batcher: 'KT1LhTpwSGcFAUUM3JYjW8XW74UHP82YzERy',
  market_maker: 'KT1BbDTB4BJWTH1CKfxYC5eB8TgrwB7WuNGF',
  token_manager: 'KT19JLvQdDGUnssfL5n6rBozZpnaej3Xfvjy',
  tzBTC_vault: 'KT1L4dArtU44J2uuneHHn1fjRfd7K6XDDuW3',
  USDT_vault: 'KT18qMEmNgvSSPEUoChDnxkVCg7eEy9UoQfj',
  USDtz_vault: 'KT1EFFWgmyu6npNZTRzB8zzuKBRnMaW8bpyN',
  BTCtz_vault: 'KT1VUVHxMjXpdQYM38hVAncUSGCz9fv78ZnP',
  EURL_vault: 'KT1RkAdLQtyKZQBCxYieH2ds4YbrLEsoDGGk',
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
