export type MarketMakerStorage = {
  vaults: {
    keys: Array<string>;
    /**
     * Bigmap ID
     */
    values: string; // Bigmap addr
  };
  administrator: string;
  batcher: string;
  tokenmanager: string;
};

// OLD types

// export type UserHoldingKey = [address, string];

// export type UserHoldings = Map<UserHoldingKey, number>;
// export type MarketMakerStorage = {
//   metadata: unknown;
//   valid_tokens: Map<TokenNames, Token>;
//   valid_swaps: Map<
//     SwapNames,
//     { swap: Swap; is_disabled_for_deposits: boolean }
//   >;
//   vaults: Map<TokenNames, Vault>;
//   last_holding_id: number;
//   user_holdings: UserHoldings;
//   vault_holdings: VaultHoldings;
// };

// MARKET MAKER HOLDINGS

// export type BatcherMarketMakerStorage = {
//   metadata: number; //! ID of metadata bigmap
//   // valid_tokens: Record<TokenNames, ContractToken>;
//   valid_tokens: Record<string, ContractToken>;
//   valid_swaps: Record<
//     SwapNames,
//     {
//       swap: Swap;
//       is_disabled_for_deposits: boolean;
//       oracle_address: string;
//       oracle_precision: string;
//       oracle_asset_name: string;
//     }
//   >;
//   // rates_current: number; //! ID of rates_current bigmap
//   // fee_in_mutez: number;
//   // batch_set: {
//   //   batches: number; //! ID of batches bigmap
//   //   current_batch_indices: Record<SwapNames, string>; //! Ex: tzBTC/USDT: "300"
//   // };
//   administrator: string; //! Address to admin
//   // fee_recipient: string; //! Address
//   // last_order_number: string; //! number in string
//   // user_batch_ordertypes: number; //! ID of order book bigmap
//   limit_on_tokens_or_pairs: string; //! 10 per default
//   // deposit_time_window_in_seconds: string; //! 600 at this time
//   // scale_factor_for_oracle_staleness: string; //! "1"

//   vault_holdings: number; //! ID of vault_holdings bigmap
//   vaults: number; //! ID of vaults bigmap
//   user_holdings: number; //! ID of user_holdings bigmap
//   batcher: string; //! burn address
// };

// export type UserHoldingsBigMapItem = {
//   key: {
//     string: TokenNames;
//     address: string;
//   };
//   value: string; // number
// };

// export type VaultHoldingsBigMapItem = {
//   key: string;
//   active: boolean;
//   value: {
//     id: string;
//     token: TokenNames;
//     holder: string;
//     shares: string; // number
//     unclaimed: string; // number
//   }; // number
// };

// export type VaultsBigMapItem = {
//   key: TokenNames;
//   value: {
//     foreign_tokens: Record<TokenNames, { token: Token; amount: string }>;
//     total_shares: string; // number
//     native_token: {
//       token: Token;
//       amount: string;
//     };
//     holdings: Array<string>; // Array<number>
//   }; // number
// };
