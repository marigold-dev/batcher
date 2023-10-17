export type TokenVaultStorage = {
  batcher: string;
  marketmaker: string;
  native_token: {
    token: {
      name: string;
      address: string;
      /**
       * Number
       */
      decimals: string;
      standard: string;
      /**
       * Number, in most case 0
       */
      token_id: string;
    };
    /**
     * Number
     */
    amount: string;
  };
  tokenmanager: string;
  /**
   * Number
   */
  total_shares: string;
  administrator: string;
  /**
   * TODO types
   */
  foreign_tokens: '';
  /**
   * Bigmap ID
   */
  vault_holdings: number;
};
