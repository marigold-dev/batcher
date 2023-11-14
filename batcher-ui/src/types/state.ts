import {
  BatcherStatus,
  PriceStrategy,
  SwapNames,
} from '@/types/contracts/batcher';
import { ValidTokenAmount } from './contracts/token-manager';

export type Token = {
  address: string | undefined;
  name: string;
  decimals: number;
  standard: 'FA1.2 token' | 'FA2 token' | undefined;
  tokenId: number;
};

export type CurrentSwap = {
  swap: {
    from: {
      token: Token;
      amount: number;
    };
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
  volumes: VolumesState;
  tokens: Map<string, Token>;
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
