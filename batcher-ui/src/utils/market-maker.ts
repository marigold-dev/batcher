// MARKET MAKER HOLDINGS

import type { MarketMakerStorage, TokenVaultStorage } from '@/types';
import { parseTokenAmount } from '@/utils/token-manager';
// import { parseTokenAmount, parseToken } from '@/utils/token-manager';
import { checkStatus } from '@/utils/utils';
// import { checkStatus, scaleAmountDown } from '@/utils/utils';

const getMarketMakerStorage = async (): Promise<MarketMakerStorage> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${process.env.NEXT_PUBLIC_MARKET_MAKER_CONTRACT_HASH}/storage`
  ).then(checkStatus);
};
const getTokenVaultStorage = async (
  vault_address: string
): Promise<TokenVaultStorage> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${vault_address}/storage`
  ).then(checkStatus);

const getVaultsFromBigmap = async (
  bigmapId: number,
  tokenName: string
): Promise<any> => {
  // ): Promise<VaultsBigMapItem> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${tokenName}`
  ).then(checkStatus);
};

const getUserVaultFromBigmap2 = async (bigmapId: number, userAddress: string) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${userAddress}`
  )
    .then(checkStatus)
    .then(vault => parseUserVault(vault.value));

const getUserVault2 = async (userAddress: string | undefined, storage: any) => {
  console.log(
    '🚀 ~ file: market-maker.ts:170 ~ getUserVault2 ~ userAddress: string, storage: any:',
    userAddress,
    storage
  );

  let userVault = {
    holder: undefined,
    shares: 0,
    unclaimed: 0,
  };

  if (!userAddress) return userVault;

  const vaultHoldings = storage.vault_holdings;
  const keys = vaultHoldings.keys;

  const userHoldingFound = keys.find(function (addr: string) {
    return addr == userAddress;
  });

  if (!userHoldingFound)
    return {
      ...userVault,
      holder: userAddress,
    };

  const holding = await getUserVaultFromBigmap2(
    vaultHoldings.values,
    userAddress
  );
  userVault = parseUserVault(holding);

  console.warn(
    '🚀 ~ file: market-maker.ts:172 ~ getUserVault2 ~ userVault:',
    userVault
  );
  return userVault;
};

const parseUserVault = (rawUserVault: any) => ({
  holder: rawUserVault.holder,
  shares: parseInt(rawUserVault.shares, 10),
  unclaimed: parseInt(rawUserVault.unclaimed),
});

const getMarketHoldings = async (
  tokenName: string,
  userAddress: string | undefined
) => {
  const mm_storage = await getMarketMakerStorage();
  console.log(
    '🚀 ~ file: market-maker.ts:91 ~ getMarketHoldings ~ market maker storage:',
    mm_storage
  );
  const vault_bigmap_id: number = parseInt(mm_storage.vaults.values);
  console.log(
    '🚀 ~ file: market-maker.ts:96 ~ getMarketHoldings ~ vault_bigmap_id:',
    vault_bigmap_id
  );
  const vault_address = (await getVaultsFromBigmap(vault_bigmap_id, tokenName))
    .value;
  console.log(
    '🚀 ~ file: market-maker.ts:101 ~ getMarketHoldings ~ vault_address:',
    vault_address
  );

  const storage = await getTokenVaultStorage(vault_address);
  console.log(
    '🚀 ~ file: market-maker.ts:107 ~ getMarketHoldings ~ vault storage:',
    storage
  );
  console.info('VAULT', storage);
  const nativeToken = parseTokenAmount(storage.native_token);
  const foreignTokens = Object.keys(storage.foreign_tokens).map(tokenAmount =>
    parseTokenAmount(tokenAmount)
  );
  const userVault = await getUserVault2(userAddress, storage);
  return {
    vault_address: vault_address,
    shares: parseInt(storage.total_shares, 10),
    nativeToken: nativeToken,
    foreignTokens: foreignTokens,
    userVault: userVault,
  };
};

export { getMarketHoldings };

// getTokenVaultStorage('tzBTC').then(console.warn);
// getUserVaultFromBigmap2(375834, 'tz1R2EoKLoJuyccMesBYGewEKCKmqqyBnYLc').then(
//   console.warn
// );
