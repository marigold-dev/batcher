export const getTokenAmount = (balances: Array<any>, standardBalance: any) => {
  const item = balances.find((item) => item.token.contract.address === standardBalance.address);
  return parseInt(item.balance) / 10 ** standardBalance.decimal;
};
