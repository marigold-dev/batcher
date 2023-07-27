import { WalletActions } from 'src/actions';
import { Loop, liftState, loop } from 'redux-loop';
import { connectWalletCmd, disconnectWalletCmd } from 'src/commands/wallet';
import { WalletState } from 'src/types';

// TODO: fp-ts

const initialState: WalletState = {
  wallet: undefined,
  userAddress: undefined,
  userAccount: undefined,
};

const walletReducer = (
  state: WalletState = initialState,
  action: WalletActions
): Loop<WalletState> | WalletState => {
  if (!state) return liftState(initialState);
  switch (action.type) {
    case 'HYDRATE_BATCHER_STATE':
      return { ...state, ...action.payload.batcherState };
    case 'CONNECT_WALLET':
      return loop(state, connectWalletCmd());
    case 'CONNECTED_WALLET':
      return {
        ...state,
        userAddress: action.payload.userAddress,
        wallet: action.payload.wallet,
        userAccount: action.payload.userAccount,
      };
    case 'DISCONNECT_WALLET':
      return loop(state, disconnectWalletCmd(state.wallet));
    case 'DISCONNECTED_WALLET':
      return {
        ...state,
        userAccount: undefined,
        wallet: undefined,
        userAddress: undefined,
      };
    default:
      return state;
  }
};

export default walletReducer;
