import { TezosToolkit } from '@taquito/taquito';
import React, { createContext, useEffect, useReducer } from 'react';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { AccountInfo, NetworkType } from '@airgap/beacon-sdk';
import { useTezosToolkit } from './tezos-toolkit';
import { getByKey, setByKey } from 'utils/local-storage';

type WalletState = {
  wallet: BeaconWallet | undefined;
  userAccount: AccountInfo | undefined;
  userAddress: string | undefined;
};

type WalletContextType = {
  connectWallet: () => void;
  disconnectWallet: () => void;
  state: WalletState;
};

const initialState: WalletState = {
  wallet: undefined,
  userAccount: undefined,
  userAddress: undefined,
};

export const WalletContext = createContext<WalletContextType>({
  state: initialState,
  connectWallet: () => {},
  disconnectWallet: () => {},
});

const connectWallet = async (tezos: TezosToolkit | undefined) => {
  if (!tezos) return Promise.reject('ERROR');
  const wallet = new BeaconWallet({
    name: 'batcher',
    preferredNetwork: NetworkType.GHOSTNET,
  });

  tezos.setWalletProvider(wallet);

  await wallet.requestPermissions({
    network: {
      type: NetworkType.GHOSTNET,
      rpcUrl: process.env.REACT_APP_TEZOS_NODE_URI,
    },
  });

  return await wallet.client.getActiveAccount().then(async userAccount => {
    const userAddress = await wallet.getPKH();

    setByKey('userAddress', userAddress);

    return { wallet, userAddress, userAccount };
  });
};

const disconnectWallet = async (
  tezos?: TezosToolkit,
  wallet?: BeaconWallet
) => {
  if (!tezos) return Promise.reject('ERROR');
  if (!wallet) return Promise.reject('ERROR: no wallet');

  wallet.clearActiveAccount();
  wallet.disconnect();

  setByKey('userAddress');

  return Promise.resolve();
};

const reducer = (
  state: WalletState,
  action:
    | {
        type: 'CONNECT_WALLET';
        payload: {
          wallet: BeaconWallet;
          userAddress: string;
          userAccount: AccountInfo | undefined;
        };
      }
    | {
        type: 'DISCONNECT_WALLET';
      }
    | {
        type: 'HYDRATE_WALLET';
        userAddress: string;
        userAccount: AccountInfo | undefined;
        wallet: BeaconWallet;
      }
) => {
  switch (action.type) {
    case 'CONNECT_WALLET':
      return { ...state, ...action.payload };
    case 'DISCONNECT_WALLET':
      return initialState;
    case 'HYDRATE_WALLET': {
      const { userAddress, userAccount, wallet } = action;
      return { ...state, userAddress, userAccount, wallet };
    }
    default:
      return state;
  }
};

export const WalletProvider = ({ children }: { children: React.ReactNode }) => {
  const { tezos } = useTezosToolkit();

  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
    const userAddress = getByKey('userAddress');

    if (userAddress) {
      const wallet = new BeaconWallet({
        name: 'batcher',
        preferredNetwork: NetworkType.GHOSTNET,
      });
      wallet.client.getActiveAccount().then(userAccount => {
        dispatch({ type: 'HYDRATE_WALLET', userAddress, userAccount, wallet });
      });

      tezos?.setWalletProvider(wallet);
    }
  }, [tezos]);

  return (
    <WalletContext.Provider
      value={{
        state,
        connectWallet: () =>
          connectWallet(tezos).then(payload =>
            dispatch({ type: 'CONNECT_WALLET', payload })
          ),
        disconnectWallet: () =>
          disconnectWallet(tezos, state.wallet).then(() => {
            dispatch({ type: 'DISCONNECT_WALLET' });
          }),
      }}>
      {children}
    </WalletContext.Provider>
  );
};

export const useWallet = () => React.useContext(WalletContext);
