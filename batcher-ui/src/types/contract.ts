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

// From Smart contract
// type Tolerance = 0 | 1 | 2;

// type Side = 0 | 1;

// Used to send params on smart contract. Tolerance must be nat (number)
//TODO: export const priceStrategyToTolerance = (
//   strategy: PriceStrategy
// ): Tolerance => {};

// ------ BATCHER STORAGE REPRESENTATION ------ //

type TokenNames = 'tzBTC' | 'EURL' | 'USDT';
type SwapNames = 'tzBTC/USDT' | 'tzBTC/EURL';

type Swap = {
  from: {
    token: Token;
    amount: number;
  };
  to: Token;
};

// type SwapReduded = {
//   from: 'tzBTC';
//   to: 'USDT' | 'EURL';
// };

export type Token = {
  token_id: number;
  name: TokenNames;
  address: string | undefined;
  decimals: number;
  standard: 'FA1.2 token' | 'FA2 token' | undefined;
};

// ---- RATES typing ----//

type ExchangeRate = {
  swap: Swap;
  rate: { p: number; q: number }; // float (Rational.t)
  when: number; // timestamp
};

export type BatcherStorage = {
  metadata: unknown;
  valid_tokens: Map<TokenNames, Token>;
  valid_swaps: Map<
    SwapNames,
    { swap: Swap; is_disabled_for_deposits: boolean }
  >;
  rates_current: Map<SwapNames, ExchangeRate>;
};



export type VolumesStorage = {
  buy_minus_volume: string;
  buy_exact_volume: string;
  buy_plus_volume: string;
  sell_minus_volume: string;
  sell_exact_volume: string;
  sell_plus_volume: string;
};