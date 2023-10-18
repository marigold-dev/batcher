import { WalletActions } from '@/actions';
import { Loop, liftState, loop } from 'redux-loop';
import { fetchUserBalancesCmd } from '@/commands/wallet';
import { WalletState } from '@/types';
import { TOKENS } from '@/utils/utils';

const initialState: WalletState = {
  userAddress: undefined,
  userBalances: TOKENS.reduce((acc, current) => ({ ...acc, [current]: 0 }), {}),
};

const walletReducer = (
  state: WalletState = initialState,
  action: WalletActions
): Loop<WalletState> | WalletState => {
  if (!state) return liftState(initialState);
  switch (action.type) {
    case 'GOT_USER_BALANCES':
      return {
        ...state,
        userBalances: action.balances.reduce(
          (acc, current) => ({
            ...acc,
            [current.name.toUpperCase()]: current.balance,
          }),
          {}
        ),
      };
    case 'FETCH_USER_BALANCES':
      return loop(state, fetchUserBalancesCmd(state.userAddress));
    case 'CONNECTED_WALLET':
      return {
        ...state,
        userAddress: action.payload.userAddress,
      };
    case 'DISCONNECTED_WALLET':
      return {
        ...state,
        userAddress: undefined,
        userBalances: TOKENS.reduce(
          (acc, current) => ({ ...acc, [current]: 0 }),
          {}
        ),
      };
    default:
      return state;
  }
};

export default walletReducer;
