export const getTokenAmount = (balances: Array<any>, standardBalance: any) => {
  const amount = balances.find((item) => {
    return item.token.contract.address === standardBalance.address
      ? parseInt(item.balance) / standardBalance.decimal
      : null;
  });

  return amount;
};
