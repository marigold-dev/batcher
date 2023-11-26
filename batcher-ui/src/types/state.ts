import {
  BatcherStatus,
  PriceStrategy,
  SwapNames,
} from '@/types/contracts/batcher';
import { ValidTokenAmount, ValidSwap } from './contracts/token-manager';

export type Token = {
  address: string | undefined;
  name: string;
  decimals: number;
  standard: 'FA1.2 token' | 'FA2 token' | undefined;
  tokenId: number;
};

export type CurrentSwap = {
  swap: {
    from: Token;
    to: Token;
  };
  isReverse: boolean;
};

export type VolumesState = {
  buy: Record<PriceStrategy, number>;
  sell: Record<PriceStrategy, number>;
};

export type ExchangeState = {
  priceStrategy: PriceStrategy;
  currentSwap: CurrentSwap;
  batcherStatus: {
    status: BatcherStatus;
    at: string | null;
    startTime: string | null;
    remainingTime: number;
  };
  batcherTimerId: number;
  swapPairName: SwapNames;
  batchNumber: number;
  oraclePrice: number;
  oraclePair: string;
  volumes: VolumesState;
  tokens: Map<string, Token>;
  swaps: Map<string, ValidSwap>;
  displayTokens: Map<string,DisplayToken>;
};

export type WalletState = {
  userAddress: string | undefined;
  userBalances: Record<string, number>;
};

export type HoldingsState = {
  open: Record<string, number>;
  cleared: Record<string, number>;
};

export type VaultToken = {
  id: number;
  name: string;
  address: string;
  decimals: number;
  amount: number;
  standard: string;
};

export type DisplayToken = {
  name: string;
  address: string;
  icon: string | undefined;
};

export type DisplaySwap = {
  pair: string;
  to: DisplayToken;
  from: DisplayToken;
};

export type UserVault = {
  shares: number;
  unclaimed: number;
};
export type GlobalVault = {
  total_shares: number;
  native: VaultToken;
  foreign: Map<string, VaultToken>;
  userVault: UserVault;
};

export type MarketHoldingsState = {
  vault_address: string;
  shares: number;
  nativeToken: ValidTokenAmount | undefined;
  foreignTokens: Array<ValidTokenAmount>;
  userVault: {
    holder: string | undefined;
    shares: number;
    unclaimed: number;
  };
};

export type EventsState = {
  toast: {
    isToastOpen: boolean;
    toastDescription: string;
    type: 'info' | 'error';
  };
};

export type AppState = {
  exchange: ExchangeState;
  wallet: WalletState;
  marketHoldings: MarketHoldingsState;
  events: EventsState;
  holdings: HoldingsState;
};
