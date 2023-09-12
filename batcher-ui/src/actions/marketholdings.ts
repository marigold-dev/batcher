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

export const updateMarketHoldings = (vaults: MarketHoldingsState) =>
  ({
    type: 'UPDATE_MARKET_HOLDINGS',
    payload: { vaults },
  }) as const;

export const getMarketHoldings = (
  contractAddress: string | undefined,
  userAddress: string | undefined
) =>
  ({
    type: 'GET_MARKET_HOLDINGS',
    payload: { contractAddress, userAddress },
  }) as const;

export type MarketHoldingsActions =
  | ReturnType<typeof addLiquidity>
  | ReturnType<typeof removeLiquidity>
  | ReturnType<typeof claimRewards>
  | ReturnType<typeof getMarketHoldings>
  | ReturnType<typeof updateMarketHoldings>;
