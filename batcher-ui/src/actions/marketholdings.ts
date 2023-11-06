import { MarketHoldingsState } from '@/types';

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
  holdings: Partial<Omit<MarketHoldingsState, 'currentVault'>>
) =>
  ({
    type: 'UPDATE_MARKET_HOLDINGS',
    payload: { holdings },
  }) as const;

export const getMarketHoldings = (
  token: string,
  userAddress: string | undefined
) =>
  ({
    type: 'GET_MARKET_HOLDINGS',
    payload: { token, userAddress },
  }) as const;

export type MarketHoldingsActions =
  | ReturnType<typeof addLiquidity>
  | ReturnType<typeof removeLiquidity>
  | ReturnType<typeof claimRewards>
  | ReturnType<typeof getMarketHoldings>
  | ReturnType<typeof updateMarketHoldings>;
