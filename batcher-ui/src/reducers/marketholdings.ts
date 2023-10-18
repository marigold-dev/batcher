import { Cmd, loop } from 'redux-loop';
import { MarketHoldingsActions } from '@/actions';
import {
  fetchGlobalVaultCmd,
  fetchMarketHoldingsCmd,
  fetchUserVaultCmd,
} from '@/commands/marketholdings';
import { MarketHoldingsState } from '@/types';

export const initialMHState: MarketHoldingsState = {
  globalVaults: {},
  userVaults: {},
  currentVault: 'tzBTC',

  currentUserVault: {
    shares: 0,
    unclaimed: 0,
  },
  currentGlobalVault: {
    shares: 0,
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
    case 'GET_USER_VAULT':
      return loop(
        state,
        fetchUserVaultCmd(action.payload.userAddress, state.currentVault)
      );
    case 'UPDATE_USER_VAULT':
      return {
        ...state,
        currentUserVault: {
          shares: action.payload.vault.shares,
          unclaimed: action.payload.vault.unclaimed,
        },
      };
    case 'GET_GLOBAL_VAULT':
      return loop(state, fetchGlobalVaultCmd(state.currentVault));
    case 'UPDATE_GLOBAL_VAULT':
      return {
        ...state,
        currentGlobalVault: {
          shares: action.payload.vault.shares,
        },
      };
    default:
      return state;
  }
};
