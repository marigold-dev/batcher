import { Cmd, loop } from 'redux-loop';
import { MarketHoldingsActions } from 'src/actions/marketholdings';
import { fetchMarketHoldingsCmd } from 'src/commands/marketholdings';
import { MarketHoldingsState } from 'src/types';

export const initialMHState: MarketHoldingsState = {
  globalVaults: {},
  userVaults: {},
  currentVault: 'tzBTC',
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
    case 'CHANGE_VAULT':
      return {
        ...state,
        currentVault: action.payload.vault,
      };
    case 'UPDATE_MARKET_HOLDINGS':
      return { ...state, ...action.payload.vaults };
    case 'GET_MARKET_HOLDINGS':
      return loop(
        state,
        fetchMarketHoldingsCmd(
          action.payload.contractAddress,
          action.payload.userAddress
        )
      );
    default:
      return state;
  }
};
