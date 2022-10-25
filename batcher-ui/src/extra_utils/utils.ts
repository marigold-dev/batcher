import * as types from './types';

export const getTokenAmount = (balances: Array<any>, standardBalance: types.token_balance) => {
  const item = balances.find(
    (item) => item.token.contract.address === standardBalance.token.address,
  );
  return parseInt(item.balance) / 10 ** standardBalance.token.decimals;
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
  standardBalance: any,
) => {
  const item = balances.find((item) => item.account.address === userAddress);
  console.log(666, item, standardBalance);
  return item ? parseInt(item.balance) / 10 ** standardBalance.decimal : 0;
};

export const getErrorMess = (error: unknown) => {
  return error instanceof Error ? error.message : 'Unknown error';
};
