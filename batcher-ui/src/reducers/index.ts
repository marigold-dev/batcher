import { TezosToolkit } from '@taquito/taquito';
import { Actions } from 'src/actions';
// import { Option, none } from 'fp-ts/Option';
import { Loop, liftState, loop } from 'redux-loop';
import { BeaconWallet } from '@taquito/beacon-wallet';
import { connectWalletCmd, disconnectWalletCmd } from 'src/commands/wallet';
import { setupTezosToolkitCmd } from 'src/commands';
import { AccountInfo } from '@airgap/beacon-sdk';

// TODO: fp-ts

export type AppState = {
  wallet: BeaconWallet | undefined;
  userAddress: string | undefined;
  userAccount: AccountInfo | undefined;
  settings: null;
  tezos: TezosToolkit | undefined;
};

// -------------- //

const initialState: AppState = {
  wallet: undefined,
  userAddress: undefined,
  userAccount: undefined,
  settings: null,
  tezos: undefined,
};

const reducer = (state: AppState, action: Actions): Loop<AppState> => {
  if (!state) return liftState(initialState);
  switch (action.type) {
    case 'HYDRATE_BATCHER_STATE':
      return liftState({ ...state, ...action.payload.batcherState });
    case 'SETUP_TEZOS_TOOLKIT':
      return loop(state, setupTezosToolkitCmd());
    case 'TEZOS_TOOLKIT_SETUPED':
      return liftState({ ...state, tezos: action.payload.tezos });
    case 'CONNECT_WALLET':
      return loop(state, connectWalletCmd());
    case 'CONNECTED_WALLET':
      return liftState({
        ...state,
        userAddress: action.payload.userAddress,
        wallet: action.payload.wallet,
        userAccount: action.payload.userAccount,
      });
    case 'DISCONNECT_WALLET':
      return loop(state, disconnectWalletCmd(state.wallet));
    case 'DISCONNECTED_WALLET':
      return liftState({
        ...state,
        userAccount: undefined,
        wallet: undefined,
        userAddress: undefined,
      });
  }
};

export const userAddressSelector = (state: AppState) => state.userAddress;
export const walletSelector = (state: AppState) => state.wallet;
export const tezosSelector = (state: AppState) => state.tezos;

export const saveToLocalStorageSelector = (state: AppState) => ({
  wallet: state.wallet,
  userAccount: state.userAccount,
  userAddress: state.userAddress,
});

export default reducer;
