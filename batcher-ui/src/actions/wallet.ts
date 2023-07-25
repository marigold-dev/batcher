// import { Option } from 'fp-ts/Option';
import { AccountInfo } from '@airgap/beacon-sdk';
import { BeaconWallet } from '@taquito/beacon-wallet';

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
  userAccount: AccountInfo;
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
export { connectWallet, disconnectWallet, connectedWallet, disconnectedWallet };

export type WalletActions =
  | ReturnType<typeof connectWallet>
  | ReturnType<typeof disconnectWallet>
  | ReturnType<typeof disconnectedWallet>
  | ReturnType<typeof connectedWallet>;
