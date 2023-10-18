// MARKET MAKER HOLDINGS

import type {
  ContractToken,
  GlobalVault,
  MarketMakerStorage,
  TokenVaultStorage,
  UserVault,
  VaultToken,
} from '@/types';
import { checkStatus, scaleAmountDown } from '@/utils/utils';
import { tokenVaultsConfig } from '@/config/token-vaults';

const getMarketMakerStorage = (): Promise<MarketMakerStorage> => {
  // const getMarketMakerStorage = (): Promise<BatcherMarketMakerStorage> => {
  return fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${process.env.NEXT_PUBLIC_MARKET_MAKER_CONTRACT_HASH}/storage`
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
  console.log(
    '🚀 ~ file: market-maker.ts:88 ~ getMarketHoldings ~ storage:',
    storage
  );
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

// ---- WIP ---- //

const getTokenVaultStorage = async (
  tokenName: string
): Promise<TokenVaultStorage> =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/contracts/${tokenVaultsConfig[tokenName]}/storage`
  ).then(checkStatus);

const getUserVaultFromBigmap2 = async (bigmapId: number, userAddress: string) =>
  fetch(
    `${process.env.NEXT_PUBLIC_TZKT_API_URI}/v1/bigmaps/${bigmapId}/keys/${userAddress}`
  ).then(checkStatus).then(vault => parseUserVault(vault.value))

const getUserVault2 = async (userAddress: string, tokenName: string) => {
  console.log("🚀 ~ file: market-maker.ts:170 ~ getUserVault2 ~ userAddress: string, tokenName: string:", userAddress, tokenName)
  const storage =await getTokenVaultStorage(tokenName);
  const userVault = await getUserVaultFromBigmap2(storage.vault_holdings, userAddress)
  console.warn("🚀 ~ file: market-maker.ts:172 ~ getUserVault2 ~ userVault:", userVault)
  return userVault
};

const parseUserVault = (rawUserVault: any) => ({
  holder: rawUserVault.holder,
  shares: parseInt(rawUserVault.shares, 10),
  unclaimed: parseInt(rawUserVault.unclaimed)
})

const getGlobalVault = async (tokenName: string)=> {
  const storage = await getTokenVaultStorage(tokenName)
  return {shares : parseInt(storage.total_shares, 10)}
}

export {getUserVault2, getGlobalVault};

// getTokenVaultStorage('tzBTC').then(console.warn);
// getUserVaultFromBigmap2(375834, 'tz1R2EoKLoJuyccMesBYGewEKCKmqqyBnYLc').then(
//   console.warn
// );