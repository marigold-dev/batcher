import * as types from "./types";

export const getTokenAmount = (balances: Array<any>, standardBalance: token_balance) => {
  const item = balances.find((item) => item.token.contract.address === standardBalance.token.address);
  return parseInt(item.balance) / 10 ** standardBalance.decimal;
};

export const rationaliseAmount = (amount: number, decimals: number) => {
  let scale = 10 ** -(decimals);
  return amount * scale;
};


