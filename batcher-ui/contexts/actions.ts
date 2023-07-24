const connectWallet = (userAddress: string) => ({
  type: 'CONNECT_WALLET',
  payload: {
    userAddress
  }
}) as const;

const disconnectWallet = () => ({
  type: 'DISCONNECT_WALLET'
}) as const;

export type Actions = ReturnType<typeof connectWallet> | ReturnType<typeof disconnectWallet>
