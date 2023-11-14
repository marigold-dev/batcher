import { LoopReducer, combineReducers } from 'redux-loop';
import exchangeReducer from '@/reducers/exchange';
import walletReducer from '@/reducers/wallet';
import {
  AppState,
  ExchangeState,
  WalletState,
  MarketHoldingsState,
  EventsState,
  HoldingsState,
} from '../types';
import { marketHoldingsReducer } from '@/reducers/marketholdings';
import { eventReducer } from '@/reducers/events';
import { holdingsReducer } from '@/reducers/holdings';

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

export const oraclePriceSelector = (state: AppState) =>
  state.exchange.oraclePrice;

export const tokensSelector = (state: AppState) => state.exchange.tokens;

export const volumesSelector = (state: AppState) => state.exchange.volumes;

// Holdings selectors
export const getHoldings = (state: AppState) => state.holdings;

// Market maker holdings selectors
export const getMarketHoldingsState = (state: AppState) => state.marketHoldings;

export const getCurrentUserVaultSelector = (state: AppState) =>
  state.marketHoldings.userVault;
export const getCurrentGlobalVaultSelector = (state: AppState) =>
  state.marketHoldings;

export const selectUserVault = (state: AppState) =>
  state.marketHoldings.userVault;

export const selectHoldings = (state: AppState) => state.marketHoldings;

export const selectCurrentVaultName = (state: AppState) =>
  state.marketHoldings.nativeToken?.token.name;

// Events selectors
export const getToastInfosSelector = (state: AppState) => state.events.toast;

export default combineReducers({
  exchange: exchangeReducer as LoopReducer<ExchangeState>,
  wallet: walletReducer as LoopReducer<WalletState>,
  marketHoldings: marketHoldingsReducer as LoopReducer<MarketHoldingsState>,
  events: eventReducer as LoopReducer<EventsState>,
  holdings: holdingsReducer as LoopReducer<HoldingsState>,
});
