export const tokenVaultsConfig: { [key: string]: string } = {
  tzBTC: process.env.NEXT_PUBLIC_TZBTC_VAULT_CONTRACT_HASH || '',
  USDT: process.env.NEXT_PUBLIC_USDT_VAULT_CONTRACT_HASH || '',
  EURL: process.env.NEXT_PUBLIC_EURL_VAULT_CONTRACT_HASH || '',
  BTCtz: process.env.NEXT_PUBLIC_BTCTZ_VAULT_CONTRACT_HASH || '',
  USDtz: process.env.NEXT_PUBLIC_USDTZ_VAULT_CONTRACT_HASH || '',
};
