import { BatcherStatus, PriceStrategy, Token } from './contract';

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
  swapPairName: string;
  batchNumber: number;
  oraclePrice: number;
  volumes: VolumesState;
};

export type WalletState = {
  userAddress: string | undefined;
  userBalances: Record<string, number>;
};

export type AppState = {
  exchange: ExchangeState;
  wallet: WalletState;
  event: {};
};
