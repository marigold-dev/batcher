import * as types from './types';

export const getTokenAmount = (balances: Array<any>, standardBalance: types.token_balance) => {
  const item = balances.find(
    (item) => item.token.contract.address === standardBalance.token.address,
  );
  return item ? parseInt(item.balance) / 10 ** standardBalance.token.decimals : 0;
};

export const scaleAmountDown = (amount: number, decimals: number) => {
  let scale = 10 ** -decimals;
  return amount * scale;
};
export const scaleAmountUp = (amount: number, decimals: number) => {
  let scale = 10 ** decimals;
  return amount * scale;
};

export const getSocketTokenAmount = (
  balances: Array<any>,
  userAddress: string,
  standardBalance: types.token_balance,
  tokenAddress: string,
) => {
  const item = balances.find(
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
