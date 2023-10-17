// MARKET MAKER HOLDINGS

import { ContractToken, GlobalVault, UserVault, VaultToken } from 'src/types';
import { checkStatus, scaleAmountDown } from './utils';

const getMarketMakerStorage = (): Promise<any> => {
  // const getMarketMakerStorage = (): Promise<BatcherMarketMakerStorage> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${process.env.NEXT_PUBLIC_MARKETMAKER_CONTRACT_HASH}/storage`
  ).then(checkStatus);
};

const getUserVaultFromBigmap = (
  bigmapId: number,
  userKey: string
  // ): Promise<UserHoldingsBigMapItem> => {
): Promise<any> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${userKey}`
  ).then(checkStatus);
};

const getHoldingsVaultFromBigmap = (
  bigmapId: number,
  key: string
  // ): Promise<VaultHoldingsBigMapItem> => {
): Promise<any> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${key}`
  ).then(checkStatus);
};
const getVaultsFromBigmap = (
  bigmapId: number,
  tokenName: string
): Promise<any> => {
  // ): Promise<VaultsBigMapItem> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${tokenName}`
  ).then(checkStatus);
};

const getUserVault = async (
  userAddress: string,
  key: string,
  userVaultId: number,
  holdingsVaultId: number
) => {
  console.warn('🚀 ~ file: utils.ts:730 ~ userAddress:', userAddress);
  if (!userAddress) {
    console.error('No user address ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }

  const userHoldings = await getUserVaultFromBigmap(userVaultId, key);
  if (!userHoldings) {
    console.error('No user vault ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }
  const holdingsVault = await getHoldingsVaultFromBigmap(
    holdingsVaultId,
    userHoldings.value
  );
  if (!holdingsVault || !holdingsVault.active) {
    console.error('No holding vault ');
    const userVault: UserVault = {
      shares: 0,
      unclaimed: 0,
    };
    return userVault;
  }
  const uv: UserVault = {
    shares: parseInt(holdingsVault.value.shares, 10),
    unclaimed: parseInt(holdingsVault.value.unclaimed, 10),
  };
  return uv;
};

export const getMarketHoldings = async (userAddress: string) => {
  const storage = await getMarketMakerStorage();
  const userVaults = await Promise.all(
    Object.keys(storage.valid_tokens).map(async token => {
      const userVaultKey: string = `{"string":"${token}","address":"${userAddress}"}`;
      const userVault = await getUserVault(
        userAddress,
        userVaultKey,
        storage.user_holdings,
        storage.vault_holdings
      );
      return {
        [token]: userVault,
      };
    })
  );

  const y = userVaults.reduce((acc, v) => {
    const name = Object.keys(v)[0];
    return { ...acc, [name]: v[name] };
  }, {});

  const globalVaults = await Promise.all(
    Object.keys(storage.valid_tokens).map(async token => {
      const t = storage.valid_tokens[token] as ContractToken & {
        token_id: number;
      };
      const b = await getVaultsFromBigmap(storage.vaults, token);
      const rtk = b.value.native_token;

      const scaleAmount = scaleAmountDown(
        parseInt(rtk.amount, 10),
        parseInt(t.decimals, 10)
      );
      const globalVault: GlobalVault = {
        total_shares: parseInt(b.value.total_shares, 10),
        native: {
          name: t.name,
          id: t.token_id,
          address: t.address,
          decimals: parseInt(t.decimals, 10),
          standard: t.standard,
          amount: scaleAmount,
        },
        foreign: new Map<string, VaultToken>(),
      };
      return { [token]: globalVault };
    })
  );

  const x = globalVaults.reduce((acc, v) => {
    const name = Object.keys(v)[0];
    return { ...acc, [name]: v[name] };
  }, {});
  return { globalVaults: x, userVaults: y };
};
