import { StringIterator } from 'lodash';
import * as types from './types';

export const getTokenAmount = (balances: any[], standardBalance: number, tokenAddress: string, tokenDecimals: number) => {
  console.log("getTokenAmount standardBalance", standardBalance);
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.token.contract.address === tokenAddress,
  );
  console.log("getTokenAmount item", item);
  return item ? parseInt(item.balance) / 10 ** tokenDecimals : 0;
};

export const scaleAmountDown = (amount: number, decimals: number) => {
  const scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  const scale = 10 ** decimals;
  return amount * scale;
};

export const getSocketTokenAmount = (
  balances: any[],
  userAddress: string,
  standardBalance: types.token_balance,
  tokenAddress: string,
) => {
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.account.address === userAddress && item.token.contract.address === tokenAddress,
  );
  return item ? parseInt(item.balance) / 10 ** standardBalance.token.decimals : 0;
};

export const getErrorMess = (error: unknown) => {
  return error instanceof Error ? error.message : 'Unknown error';
};

export const orders_exist_in_order_book = (ob: types.order_book) => {
  try {
    return ob.bids.length > 0 || ob.asks.length > 0;
  } catch {
    return false;
  }
};

export const getEmptyOrderBook = () => {
  return {
    bids: [],
    asks: [],
  };
};

export const getNetworkType = () => {
  const network = REACT_APP_NETWORK_TARGET;
  if (network?.includes('GHOSTNET')) {
    return types.NetworkType.GHOSTNET;
  } else {
    return types.NetworkType.KATHMANDUNET;
  }
};

export const getEmptyVolumes = () => {
  return {
    buy_minus_volume: '0',
    buy_exact_volume: '0',
    buy_plus_volume: '0',
    sell_minus_volume: '0',
    sell_exact_volume: '0',
    sell_plus_volume: '0',
  };
};

export const scaleStringAmountDown = (amount: string, decimals: number) => {
  const scale = 10 ** -decimals;
  return (Number.parseInt(amount) * scale).toString();
};
