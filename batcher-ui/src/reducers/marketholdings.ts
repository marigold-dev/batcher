import { Cmd, loop } from 'redux-loop';
import { MarketHoldingsActions } from '@/actions';
import { fetchMarketHoldingsCmd } from '@/commands/marketholdings';
import { MarketHoldingsState } from '@/types';

export const initialMHState: MarketHoldingsState = {
  vault_address:'',
  shares: 0,
  nativeToken: {
    token: {
      name: 'tzBTC',
      address: '',
      token_id: '0',
      decimals: '8',
      standard: '',
    },
    amount: 0,
  },
  foreignTokens: [],
  userVault: {
    holder: '',
    shares: 0,
    unclaimed: 0,
  },
};

export const marketHoldingsReducer = (
  state: MarketHoldingsState = initialMHState,
  action: MarketHoldingsActions
) => {
  switch (action.type) {
    case 'ADDLIQUIDITY':
      //TODO
      return loop(state, Cmd.none);
    case 'REMOVELIQUIDITY':
      //TODO
      return loop(state, Cmd.none);
    case 'CLAIMREWARDS':
      //TODO
      return loop(state, Cmd.none);
    case 'UPDATE_MARKET_HOLDINGS':
      return { ...state, ...action.payload.holdings };
    case 'GET_MARKET_HOLDINGS':
      return loop(
        state,
        fetchMarketHoldingsCmd(action.payload.token, action.payload.userAddress)
      );
    default:
      return state;
  }
};
