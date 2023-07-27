import { Cmd } from 'redux-loop';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { getNetworkType } from '../../extra_utils/utils';
import { tezosSelector, walletSelector } from 'src/reducers';
// import * as O from 'fp-ts/Option';
// import { pipe } from 'fp-ts/function';
import { connectedWallet, disconnectedWallet } from 'src/actions';
import { AccountInfo } from '@airgap/beacon-sdk';

const connectWalletCmd = () => {
  return Cmd.run(
    getState => {
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: getNetworkType(),
      });

      const tezos = tezosSelector(getState());

      if (!wallet || !tezos) {
        return Promise.reject('TODO Manage error : no wallet');
      }

      return wallet
        .requestPermissions({
          network: {
            type: getNetworkType(),
            rpcUrl: process.env.REACT_APP_TEZOS_NODE_URI,
          },
        })
        .then(() => {
          tezos.setWalletProvider(wallet);
        })
        .then(() => wallet.client.getActiveAccount())
        .then(async userAccount => {
          const userAddress = await wallet.getPKH();

          return { wallet, userAddress, userAccount };
        });
    },
    {
      args: [Cmd.getState],
      //TODO: manage errors
      successActionCreator: ({
        wallet,
        userAddress,
        userAccount,
      }: {
        wallet: BeaconWallet;
        userAddress: string;
        userAccount?: AccountInfo;
      }) => {
        console.log(wallet, userAddress);
        return connectedWallet({ wallet, userAddress, userAccount });
      },
    }
  );
};

const connectedWalletCmd = () => {
  return Cmd.run(
    getState => {
      const tezos = tezosSelector(getState());
      const wallet = walletSelector(getState());

      //TODO: manage errors
      if (!wallet || !tezos)
        return console.error('TODO Manage error : no wallet');

      tezos.setWalletProvider(wallet);
    },
    { args: [Cmd.getState] }
  );
};

const disconnectWalletCmd = (wallet?: BeaconWallet) => {
  return Cmd.run(
    async () => {
      if (!wallet) return Promise.reject('No Wallet ! ');
      await wallet.clearActiveAccount();

      return Promise.resolve();
    },
    {
      successActionCreator: disconnectedWallet,
    }
  );
};

export { connectWalletCmd, connectedWalletCmd, disconnectWalletCmd };
