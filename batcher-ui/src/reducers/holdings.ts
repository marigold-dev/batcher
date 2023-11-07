import { Cmd, loop } from 'redux-loop';
import { HoldingsActions } from '@/actions/holdings';
import { fetchHoldingsCmd } from '@/commands/holdings';
import { HoldingsState } from '@/types';

const initialState: HoldingsState = {
  open: { tzBTC: 0, USDT: 0, EURL: 0 },
  cleared: { tzBTC: 0, USDT: 0, EURL: 0 },
};

export const holdingsReducer = (
  state: HoldingsState = initialState,
  action: HoldingsActions
) => {
  switch (action.type) {
    case 'REDEEM':
      //TODO redeem with Redux
      return loop(state, Cmd.none);
    case 'UPDATE_HOLDINGS':
      return { ...state, ...action.payload.holdings };
    case 'GET_HOLDINGS':
      return loop(state, fetchHoldingsCmd(action.payload.userAddress));
    default:
      return state;
  }
};
