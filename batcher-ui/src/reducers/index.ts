import { LoopReducer, combineReducers } from 'redux-loop';
import exchangeReducer from './exchange';
import walletReducer from './wallet';
import {
  AppState,
  ExchangeState,
  WalletState,
  MarketHoldingsState,
} from '../types';
import { eventReducer } from './events';
import { holdingsReducer } from './holdings';
import { marketHoldingsReducer } from './marketholdings';

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

export const volumesSelector = (state: AppState) => state.exchange.volumes;

// Holdings selectors
export const getHoldings = (state: AppState) => state.holdings;

// Market maker holdings selectors
export const getMarketHoldingsState = (state: AppState) => state.marketHoldings;

export const getCurrentUserVaultSelector = (state: AppState) =>
  state.marketHoldings.userVaults.get(state.marketHoldings.currentVault);
export const getCurrentGlobalVaultSelector = (state: AppState) =>
  state.marketHoldings.globalVaults.get(state.marketHoldings.currentVault);

export const getCurrentVaultName = (state: AppState) =>
  state.marketHoldings.currentVault;

export const getGlobalVaults = (state: AppState) =>
  state.marketHoldings.globalVaults;


export default combineReducers({
  exchange: exchangeReducer as LoopReducer<ExchangeState>,
  wallet: walletReducer as LoopReducer<WalletState>,
  event: eventReducer as LoopReducer<{}>,
  holdings: holdingsReducer as LoopReducer<{}>,
  marketHoldings: marketHoldingsReducer as LoopReducer<MarketHoldingsState>,
});
