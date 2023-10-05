import { Cmd, loop } from 'redux-loop';
import { MarketHoldingsActions } from 'src/actions/marketholdings';
import { fetchMarketHoldingsCmd } from 'src/commands/marketholdings';
import { MarketHoldingsState, VaultToken } from 'src/types';

// export const initialMVault: MVault = {
//   global: {
//     total_shares: 0,
//     native: {
//       id: 0,
//       name: 'tzBTC',
//       amount: 0,
//       address: '',
//       decimals: 8,
//       standard: 'FA1.2 token',
//     },
//     foreign: new Map<string, VaultToken>(),
//   },
//   user: {
//     shares: 0,
//     unclaimed: 0,
//   },
// };

export const initialMHState: MarketHoldingsState = {
  globalVaults: new Map(),
  userVaults: new Map(),
  currentVault: '',
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
