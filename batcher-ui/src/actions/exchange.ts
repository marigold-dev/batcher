import { PriceStrategy } from '../types';

export const updatePriceStrategy = (priceStrategy: PriceStrategy) =>
  ({
    type: 'UDPATE_PRICE_STATEGY',
    payload: { priceStrategy },
  } as const);

export const reverseSwap = () =>
  ({
    type: 'REVERSE_SWAP',
  } as const);

export const changePair = (pair: string) =>
  ({
    type: 'CHANGE_PAIR',
    payload: { pair },
  } as const);

export type ExchangeActions =
  | ReturnType<typeof updatePriceStrategy>
  | ReturnType<typeof reverseSwap>
  | ReturnType<typeof changePair>;
