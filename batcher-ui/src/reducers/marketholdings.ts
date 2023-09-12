import { Cmd, loop } from 'redux-loop';
import { MarketHoldingsActions } from 'src/actions/marketholdings';
import { fetchMarketHoldingsCmd } from 'src/commands/marketholdings';
import { MarketHoldingsState, MVault } from 'src/types';

const initialState: MarketHoldingsState = {
  vaults: new Map<string,MVault>
};

export const marketHoldingsReducer = (
  state: MarketHoldingsState = initialState,
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
      return { ...state, ...action.payload.vaults };
    case 'GET_MARKET_HOLDINGS':
      return loop(state, fetchMarketHoldingsCmd(action.payload.contractAddress, action.payload.userAddress));
    default:
      return state;
  }
};
