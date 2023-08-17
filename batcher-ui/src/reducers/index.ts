import { LoopReducer, combineReducers } from 'redux-loop';
import exchangeReducer from './exchange';
import walletReducer from './wallet';
import { AppState, ExchangeState, WalletState } from 'src/types';

// Wallet selectors
export const userAddressSelector = (state: AppState) => {
  return state.wallet.userAddress;
};

export const userBalancesSelector = (state: AppState) =>
  state.wallet.userBalances;

// Exchange selectors
export const priceStrategySelector = (state: AppState) =>
  state.exchange.priceStrategy;

export const currentSwapSelector = (state: AppState) =>
  state.exchange.currentSwap;

export const currentPairSelector = (state: AppState) =>
  state.exchange.swapPairName;

export const batcherStatusSelector = (state: AppState) =>
  state.exchange.batcherStatus.status;

export const batcherStatusTimeSelector = (state: AppState) =>
  state.exchange.batcherStatus.at;

export const batchStartTimeSelector = (state: AppState) =>
  state.exchange.batcherStatus.startTime;

export const remainingTimeSelector = (state: AppState) =>
  state.exchange.batcherStatus.remainingTime;

export const batchNumberSelector = (state: AppState) =>
  state.exchange.batchNumber;

export default combineReducers({
  exchange: exchangeReducer as LoopReducer<ExchangeState>,
  wallet: walletReducer as LoopReducer<WalletState>,
});
