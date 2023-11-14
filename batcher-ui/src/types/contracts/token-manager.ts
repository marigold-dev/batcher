
export type TokenManagerStorage = {
  valid_swaps: {
    /**
     * Ex : "tzBTC/USDT"
     */
    keys: Array<string>;
    /**
     * Bigmap ID
     */
    values: number;
  };
  valid_tokens: {
    /**
     * Ex : "tzBTC"
     */
    keys: Array<string>;
    /**
     * Bigmap ID
     */
    values: number;
  };
  administrator: string;
  /**
   * Number. Currently 10
   */
  limit_on_tokens_or_pairs: string;
};

export type ValidToken = {
  name: string;
  address: string;
  token_id: string;
  decimals: string;
  standard: string;
};

export type Swap = {
  from: string;
  to: string;
};

export type ValidSwap = {
  swap: Swap;
  oracle_address: string;
  oracle_asset_name: string;
  oracle_precision: number;
  is_disabled_for_deposits: boolean;
};

export type ValidTokenAmount = {
  token: ValidToken;
  amount: number;
}

export type ValidTokensBigmapItem = {
  key: string;
  value: ValidToken;
};
export type ValidSwapsBigmapItem = {
  key: string;
  value: ValidSwap;
};
