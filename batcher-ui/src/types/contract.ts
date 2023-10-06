import { Token } from './state';

export enum BatcherStatus {
  OPEN = 'OPEN',
  CLOSED = 'CLOSED',
  CLEARED = 'CLEARED',
  NONE = 'NONE',
}

export enum PriceStrategy {
  WORSE = 'WORSE',
  EXACT = 'EXACT',
  BETTER = 'BETTER',
}

// ------ BATCHER STORAGE REPRESENTATION ------ //

export type TokenNames = 'tzBTC' | 'EURL' | 'USDT' | 'BTCtz' | 'USDtz';
export type SwapNames =
  | 'tzBTC/USDT'
  | 'tzBTC/EURL'
  | 'BTCtz/USDT'
  | 'BTCtz/USDtz'
  | 'tzBTC/USDtz';

type Swap = {
  from: {
    token: ContractToken;
    amount: string;
  };
  to: ContractToken;
};

export type ContractToken = {
  name: TokenNames;
  address: string;
  decimals: string;
  standard: 'FA1.2 token' | 'FA2 token';
};

export type VolumesStorage = {
  buy_minus_volume: string;
  buy_exact_volume: string;
  buy_plus_volume: string;
  sell_minus_volume: string;
  sell_exact_volume: string;
  sell_plus_volume: string;
};

export type PairStorage = {
  address_0: string;
  address_1: string;
  decimals_0: string;
  decimals_1: string;
  name_0: string;
  name_1: string;
  standard_0: string;
  standard_1: string;
};

type P<K extends string> = {
  [key in K]: {};
};

export type UserOrder = {
  key: {
    side: P<'buy'> | P<'sell'>;
    tolerance: P<'exact'> | P<'minus'> | P<'plus'>;
  };
  value: string; //! amount in mutez
};

export type BatchStatusOpen = { open: string };
export type BatchStatusClosed = {
  closed: { closing_time: string; start_time: string };
};

type Rate = {
  swap: Swap;
  rate: { p: string; q: string }; // float (Rational.t)
  when: string; // timestamp
};

export type BatchStatusCleared = {
  cleared: {
    at: string;
    clearing: {
      clearing_rate: Rate;
      clearing_tolerance: P<'exact'> | P<'minus'> | P<'plus'>;
      clearing_volumes: { exact: string; minus: string; plus: string };
      total_cleared_volumes: {
        buy_side_total_cleared_volume: string;
        buy_side_volume_subject_to_clearing: string;
        sell_side_total_cleared_volume: string;
        sell_side_volume_subject_to_clearing: string;
      };
    };
    rate: Rate;
  };
};

export type BatcherStatusStorage =
  | BatchStatusOpen
  | BatchStatusClosed
  | BatchStatusCleared;

export const batchIsCleared = (
  status: BatcherStatusStorage
): status is BatchStatusCleared => {
  return Object.keys(status)[0] === 'cleared';
};

export type TokenAmount = {
  token: Token;
  amount: number;
};

export type Vault = {
  total_shares: number;
  holdings: Set<number>;
  native_token: TokenAmount;
  foreign_tokens: Map<string, TokenAmount>;
};

export type address = string;

export type UserHoldingKey = [address, string];

export type UserHoldings = Map<UserHoldingKey, number>;

export type MarketVaultHolding = {
  id: number;
  token: string;
  holder: address;
  shares: number;
  unclaimed: number;
};
export type VaultHoldings = Map<number, MarketVaultHolding>;

export type MarketMakerStorage = {
  metadata: unknown;
  valid_tokens: Map<TokenNames, Token>;
  valid_swaps: Map<
    SwapNames,
    { swap: Swap; is_disabled_for_deposits: boolean }
  >;
  vaults: Map<TokenNames, Vault>;
  last_holding_id: number;
  user_holdings: UserHoldings;
  vault_holdings: VaultHoldings;
};

export type BatcherStorage = {
  metadata: number; //! ID of metadata bigmap
  valid_tokens: Record<TokenNames, ContractToken>;
  valid_swaps: Record<
    SwapNames,
    {
      swap: Swap;
      is_disabled_for_deposits: boolean;
      oracle_address: string;
      oracle_precision: string;
      oracle_asset_name: string;
    }
  >;
  rates_current: number; //! ID of rates_current bigmap
  fee_in_mutez: number;
  batch_set: {
    batches: number; //! ID of batches bigmap
    current_batch_indices: Record<SwapNames, string>; //! Ex: tzBTC/USDT: "300"
  };
  administrator: string; //! Address to admin
  fee_recipient: string; //! Address
  last_order_number: string; //! number in string
  user_batch_ordertypes: number; //! ID of order book bigmap
  limit_on_tokens_or_pairs: string; //! 10 per default
  deposit_time_window_in_seconds: string; //! 600 at this time
  scale_factor_for_oracle_staleness: string; //! "1"
};

export type RatesCurrentBigmap = {
  swap: Swap;
  rate: { p: string; q: string }; // float (Rational.t)
  when: string; // timestamp
};

export type BatchBigmap = {
  batch_number: string;
  volumes: VolumesStorage;
  status: BatcherStatusStorage;
  pair: PairStorage;
};

export type OrderBookBigmap = {
  [key: string]: Array<UserOrder>;
};

// MARKET MAKER HOLDINGS

export type BatcherMarketMakerStorage = {
  metadata: number; //! ID of metadata bigmap
  valid_tokens: Record<string, ContractToken>;
  valid_swaps: Record<
    SwapNames,
    {
      swap: Swap;
      is_disabled_for_deposits: boolean;
      oracle_address: string;
      oracle_precision: string;
      oracle_asset_name: string;
    }
  >;
  administrator: string; //! Address to admin
  limit_on_tokens_or_pairs: string; //! 10 per default
  vault_holdings: number; //! ID of vault_holdings bigmap
  vaults: number; //! ID of vaults bigmap
  user_holdings: number; //! ID of user_holdings bigmap
  batcher: string; //! burn address
};

export type UserHoldingsBigMapItem = {
  key: {
    string: TokenNames;
    address: string;
  };
  value: string; // number
};

export type VaultHoldingsBigMapItem = {
  key: string;
  active: boolean;
  value: {
    id: string;
    token: TokenNames;
    holder: string;
    shares: string; // number
    unclaimed: string; // number
  }; // number
};

export type VaultsBigMapItem = {
  key: TokenNames;
  value: {
    foreign_tokens: Record<TokenNames, { token: Token; amount: string }>;
    total_shares: string; // number
    native_token: {
      token: Token;
      amount: string;
    };
    holdings: Array<string>; // Array<number>
  }; // number
};

