// import { Option } from 'fp-ts/Option';
import { AccountInfo } from '@airgap/beacon-sdk';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { WalletState } from 'src/types';

const connectWallet = () =>
  ({
    type: 'CONNECT_WALLET',
  } as const);

const connectedWallet = ({
  wallet,
  userAddress,
  userAccount,
}: {
  wallet: BeaconWallet;
  userAddress: string;
  userAccount?: AccountInfo;
}) =>
  ({
    type: 'CONNECTED_WALLET',
    payload: {
      wallet,
      userAddress,
      userAccount,
    },
  } as const);

const disconnectWallet = () =>
  ({
    type: 'DISCONNECT_WALLET',
  } as const);

const disconnectedWallet = () =>
  ({
    type: 'DISCONNECTED_WALLET',
  } as const);

const hydrateBatcherState = (batcherState: WalletState) =>
  ({
    type: 'HYDRATE_BATCHER_STATE',
    payload: { batcherState },
  } as const);

const getUserBalances = (fetchh?: any) =>
  ({
    type: 'GET_USER_BALANCES',
    fetchh,
  } as const);

export {
  connectWallet,
  disconnectWallet,
  connectedWallet,
  disconnectedWallet,
  hydrateBatcherState,
  getUserBalances,
};

export type WalletActions =
  | ReturnType<typeof connectWallet>
  | ReturnType<typeof disconnectWallet>
  | ReturnType<typeof disconnectedWallet>
  | ReturnType<typeof connectedWallet>
  | ReturnType<typeof hydrateBatcherState>
  | ReturnType<typeof getUserBalances>;
