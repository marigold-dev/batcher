import { Cmd } from 'redux-loop';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { getNetworkType } from '../../extra_utils/utils';
import {
  saveToLocalStorageSelector,
  tezosSelector,
  walletSelector,
} from 'src/reducers';
// import * as O from 'fp-ts/Option';
// import { pipe } from 'fp-ts/function';
import { connectedWallet, disconnectedWallet } from 'src/actions';
import { setByKey } from '../../extra_utils/local-storage';

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
      successActionCreator: ({ wallet, userAddress, userAccount }) => {
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
      const localStorageState = saveToLocalStorageSelector(getState());

      //TODO: manage errors
      if (!wallet || !tezos)
        return console.error('TODO Manage error : no wallet');

      tezos.setWalletProvider(wallet);
    },
    { args: [Cmd.getState] }
  );
};

const disconnectWalletCmd = (wallet: BeaconWallet) => {
  return Cmd.run(
    async dispatch => {
      if (!wallet) return Promise.reject('No Wallet ! ');
      await wallet.clearActiveAccount();

      setByKey(process.env.REACT_APP_LOCAL_STORAGE_KEY_STATE, {});

      return Promise.resolve();
    },
    {
      successActionCreator: disconnectedWallet,
    }
  );
};

export { connectWalletCmd, connectedWalletCmd, disconnectWalletCmd };
