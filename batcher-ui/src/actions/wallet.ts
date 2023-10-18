import { Balances } from '@/utils/utils';

const connectedWallet = ({ userAddress }: { userAddress: string }) =>
  ({
    type: 'CONNECTED_WALLET',
    payload: {
      userAddress,
    },
  } as const);

const disconnectedWallet = () =>
  ({
    type: 'DISCONNECTED_WALLET',
  } as const);

const fetchUserBalances = () =>
  ({
    type: 'FETCH_USER_BALANCES',
  } as const);

const gotUserBalances = (balances: Balances) =>
  ({
    type: 'GOT_USER_BALANCES',
    balances,
  } as const);

export {
  connectedWallet,
  disconnectedWallet,
  fetchUserBalances,
  gotUserBalances,
};

export type WalletActions =
  | ReturnType<typeof disconnectedWallet>
  | ReturnType<typeof connectedWallet>
  | ReturnType<typeof fetchUserBalances>
  | ReturnType<typeof gotUserBalances>;
