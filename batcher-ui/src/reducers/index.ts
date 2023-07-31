import { LoopReducer, combineReducers } from 'redux-loop';
import exchangeReducer from './exchange';
import miscReducer from './misc';
import walletReducer from './wallet';
import { AppState, ExchangeState, MiscState, WalletState } from 'src/types';

// Wallet selectors
export const userAddressSelector = (state: AppState) => {
  return state.wallet.userAddress;
};

export const walletSelector = (state: AppState) => state.wallet.wallet;

export const userBalancesSelector = (state: AppState) =>
  state.wallet.userBalances;

// Misc selectors
export const tezosSelector = (state: AppState) => state.misc.tezos;

export const batcherStatusSelector = (state: AppState) =>
  state.misc.batcherStatus;

// Exchange selectors
export const priceStrategySelector = (state: AppState) =>
  state.exchange.priceStrategy;

export const currentSwapSelector = (state: AppState) =>
  state.exchange.currentSwap;



export default combineReducers({
  misc: miscReducer as LoopReducer<MiscState>,
  exchange: exchangeReducer as LoopReducer<ExchangeState>,
  wallet: walletReducer as LoopReducer<WalletState>,
});
