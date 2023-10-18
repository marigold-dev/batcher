import { MarketHoldingsState } from '@/types';

export const addLiquidity = () =>
  ({
    type: 'ADDLIQUIDITY',
  } as const);

export const removeLiquidity = () =>
  ({
    type: 'REMOVELIQUIDITY',
  } as const);

export const claimRewards = () =>
  ({
    type: 'CLAIMREWARDS',
  } as const);

export const updateMarketHoldings = (
  vaults: Partial<Omit<MarketHoldingsState, 'currentVault'>>
) =>
  ({
    type: 'UPDATE_MARKET_HOLDINGS',
    payload: { vaults },
  } as const);

export const getMarketHoldings = (
  contractAddress: string,
  userAddress: string
) =>
  ({
    type: 'GET_MARKET_HOLDINGS',
    payload: { contractAddress, userAddress },
  } as const);

export const changeVault = (vault: string) =>
  ({
    type: 'CHANGE_VAULT',
    payload: { vault },
  } as const);

// ---- WIP ---- //

export const getUserVault = (userAddress: string) =>
  ({
    type: 'GET_USER_VAULT',
    payload: { userAddress },
  } as const);

export const updateUserVault = (vault: any) =>
  ({
    type: 'UPDATE_USER_VAULT',
    payload: { vault },
  } as const);

export const getGlobalVault = () =>
  ({
    type: 'GET_GLOBAL_VAULT',
  } as const);

export const updateGlobalVault = (vault: any) =>
  ({
    type: 'UPDATE_GLOBAL_VAULT',
    payload: { vault },
  } as const);

export type MarketHoldingsActions =
  | ReturnType<typeof addLiquidity>
  | ReturnType<typeof removeLiquidity>
  | ReturnType<typeof claimRewards>
  | ReturnType<typeof changeVault>
  | ReturnType<typeof getMarketHoldings>
  | ReturnType<typeof getUserVault>
  | ReturnType<typeof updateUserVault>
  | ReturnType<typeof getGlobalVault>
  | ReturnType<typeof updateGlobalVault>
  | ReturnType<typeof updateMarketHoldings>;
