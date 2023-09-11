import { TezosToolkit } from '@taquito/taquito';
import React, { createContext, useEffect, useReducer } from 'react';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { AccountInfo, NetworkType } from '@airgap/beacon-sdk';
import { useTezosToolkit } from './tezos-toolkit';

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
    // @ts-ignore
    preferredNetwork:
      process.env.NEXT_PUBLIC_NETWORK_TARGET === 'GHOSTNET'
        ? NetworkType.GHOSTNET
        : NetworkType.MAINNET,
  });

  //TODO: Find a way to fix error "Argument of type 'BeaconWallet' is not assignable to parameter of type 'WalletProvider'.
  // @ts-ignore
  tezos.setWalletProvider(wallet);

  await wallet.requestPermissions({
    network: {
      // @ts-ignore
      type:
        process.env.NEXT_PUBLIC_NETWORK_TARGET === 'GHOSTNET'
          ? NetworkType.GHOSTNET
          : NetworkType.MAINNET,
      rpcUrl: process.env.NEXT_PUBLIC_TEZOS_NODE_URI,
    },
  });

  return await wallet.client.getActiveAccount().then(async userAccount => {
    const userAddress = await wallet.getPKH();

    return { wallet, userAddress, userAccount };
  });
};

const disconnectWallet = async (
  tezos?: TezosToolkit,
  wallet?: BeaconWallet
) => {
  if (!tezos) return Promise.reject('Error: Tezos Toolkit is not initialized.');
  if (!wallet) return Promise.reject("Error: No wallet. Can't disconnected.");

  wallet.clearActiveAccount();
  wallet.disconnect();

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
        userAddress: string | undefined;
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
    const wallet = new BeaconWallet({
      name: 'batcher',
      // @ts-ignore
      preferredNetwork:
        process.env.NEXT_PUBLIC_NETWORK_TARGET === 'GHOSTNET'
          ? NetworkType.GHOSTNET
          : NetworkType.MAINNET,
    });

    //TODO: Find a way to fix error "Argument of type 'BeaconWallet' is not assignable to parameter of type 'WalletProvider'.
    // @ts-ignore
    tezos?.setWalletProvider(wallet);

    wallet.client.getActiveAccount().then(userAccount => {
      dispatch({
        type: 'HYDRATE_WALLET',
        userAddress: userAccount?.address,
        userAccount,
        wallet,
      });
    });
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
