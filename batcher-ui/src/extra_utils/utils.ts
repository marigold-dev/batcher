import { StringIterator } from 'lodash';
import * as types from './types';
import { Dispatch, SetStateAction } from 'react';

export const setTokenAmount = (balances: any[], standardBalance: number, tokenAddress: string, tokenDecimals: number, setBalance: Dispatch<SetStateAction<number>>) => {
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.token.contract.address === tokenAddress,
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** tokenDecimals : 0;
  setBalance(tokAmount);
};

export const scaleAmountDown = (amount: number, decimals: number) => {
  const scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  const scale = 10 ** decimals;
  return amount * scale;
};

export const setSocketTokenAmount = (
  balances: any[],
  userAddress: string,
  token: types.token,
  setBalance: Dispatch<SetStateAction<number>>,
) => {
  const item = balances.find(
    // eslint-disable-next-line @typescript-eslint/no-shadow
    (item) => item.account.address === userAddress && item.token.contract.address === token.address,
  );
  const tokAmount = item ? parseInt(item.balance) / 10 ** token.decimals : 0;
  setBalance(tokAmount);
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
  if(!amount){
    console.error("scaleStringAmountDown - amount is undefined", amount)
    return '0';
  } else {
    const scale = 10 ** -decimals;
    return (Number.parseInt(amount) * scale).toString();
  }
};

