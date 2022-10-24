// Common process in batcher UI

export const getTokenAmount = (balances: Array<any>, standardBalance: any) => {
  const item = balances.find((item) => item.token.contract.address === standardBalance.address);
  return parseInt(item.balance) / 10 ** standardBalance.decimal;
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

export const rationaliseAmount = (amount: number, decimal: number) => {
  let scale = 10 ** decimal;
  return amount * scale;
};

export const getErrorMess = (error: unknown) => {
  return error instanceof Error ? error.message : 'Unknown error';
};
