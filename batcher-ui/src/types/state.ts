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

export type HoldingsState = {
  open: Record<string, number>;
  cleared: Record<string, number>;
};

export type VaultToken = {
  name: string;
  amount: number;
};

export type GlobalVault = {
  total_shares: number;
  native: VaultToken;
  foreign: Map<string, VaultToken>;
};

export type UserVault = {
  shares: number;
  unclaimed: number;
};

export type MVault = {
  global: GlobalVault;
  user: UserVault;
};

export type MarketHoldingsState = {
  vaults: Map<string, MVault>;
  current_vault: MVault;
};

export type AppState = {
  exchange: ExchangeState;
  wallet: WalletState;
  event: {};
  holdings: HoldingsState;
  marketHoldings: MarketHoldingsState;
};

export const initialMVault: MVault = {
  global: {
    total_shares: 0,
    native: {
      name: 'tzBTC',
      amount: 0,
    },
    foreign: new Map<string, VaultToken>(),
  },
  user: {
    shares: 0,
    unclaimed: 0,
  },
};

export const initialMHState: MarketHoldingsState = {
  vaults: new Map<string, MVault>(),
  current_vault: initialMVault,
};
