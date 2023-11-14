import { HoldingsState, Token } from '@/types';

export const redeem = () =>
  ({
    type: 'REDEEM',
  }) as const;

export const updateHoldings = (holdings: HoldingsState) =>
  ({
    type: 'UPDATE_HOLDINGS',
    payload: { holdings },
  }) as const;

export const getHoldings = (
  userAddress: string | undefined,
  tokens: Map<string, Token>
) =>
  ({
    type: 'GET_HOLDINGS',
    payload: { userAddress, tokens },
  }) as const;

export type HoldingsActions =
  | ReturnType<typeof redeem>
  | ReturnType<typeof getHoldings>
  | ReturnType<typeof updateHoldings>;
