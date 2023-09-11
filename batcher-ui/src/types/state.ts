import { BatcherStatus, PriceStrategy, SwapNames } from './contract';

type Token = {
  address: string | undefined;
  name: string;
  decimals: number;
  standard: 'FA1.2 token' | 'FA2 token' | undefined;
  tokenId: 0;
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
};

export type WalletState = {
  userAddress: string | undefined;
  userBalances: Record<string, number>;
};

export type HoldingsState = {
  open: Record<string, number>;
  cleared: Record<string, number>;
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
  events: EventsState;
  holdings: HoldingsState;
};