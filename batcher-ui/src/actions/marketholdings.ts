import { MarketHoldingsState } from 'src/types';

export const addLiquidity = () =>
  ({
    type: 'ADDLIQUIDITY',
  }) as const;

export const removeLiquidity = () =>
  ({
    type: 'REMOVELIQUIDITY',
  }) as const;

export const claimRewards = () =>
  ({
    type: 'CLAIMREWARDS',
  }) as const;

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
  }) as const;

export const changeVault = (vault: string) =>
  ({
    type: 'CHANGE_VAULT',
    payload: { vault },
  }) as const;

export type MarketHoldingsActions =
  | ReturnType<typeof addLiquidity>
  | ReturnType<typeof removeLiquidity>
  | ReturnType<typeof claimRewards>
  | ReturnType<typeof changeVault>
  | ReturnType<typeof getMarketHoldings>
  | ReturnType<typeof updateMarketHoldings>;
