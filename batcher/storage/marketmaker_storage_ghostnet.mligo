#import "../marketmaker.mligo" "MarketMaker"

let f(_:unit) : MarketMaker.Storage.t = {
  metadata = (Big_map.empty : MarketMaker.metadata);
  valid_tokens = Map.literal [
    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("BTCtz"), {
      token_id = 0n;
      name = "BTCtz";
      address = Some(("KT1ErLEYVsxqHxLgLucXViq5DYrtSyDuSFTe" : address));
      decimals = 8n;
      standard = Some "FA2 token"
    });
    (("EURL"),{
      token_id = 0n;
      name = "EURL";
      address = Some(("KT1RcHjqDWWycYQGrz4KBYoGZSMmMuVpkmuS" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      token_id = 0n;
      name = "USDT";
      address = Some(("KT1WNrZ7pEbpmYBGPib1e7UVCeC6GA6TkJYR" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDtz"),{
      token_id = 0n;
      name = "USDtz";
      address = Some(("KT1B8tP5Q8Cb7HctLfxt4MVk2cWouHFrnbjW" : address));
      decimals = 6n;
      standard = Some "FA1.2 token"
    })
  ];
  valid_swaps = Map.literal [
    ("tzBTC/USDT", {
        swap = {
            from =  "tzBTC";
            to =  "USDT";
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("BTCtz/USDtz", {
        swap = {
            from =  "BTCtz";
            to =  "USDtz";
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC/USDtz", {
        swap = {
            from =  "tzBTC";
            to =  "USDtz";
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("BTCtz/USDT", {
        swap = {
            from =  "BTCtz";
            to =  "USDT";
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC/EURL", {
        swap = {
          from = "tzBTC";
          to = "EURL";
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
        oracle_asset_name = "BTC-EUR";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  batcher = ("KT1LhTpwSGcFAUUM3JYjW8XW74UHP82YzERy" :  address);
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  vaults = Big_map.literal [
    ("tzBTC", {
      total_shares = 0n;
      holdings = (Set.empty: nat set);
      native_token = {
        token = {
          token_id = 0n;
          name = "tzBTC";
          address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
          decimals = 8n;
          standard = Some "FA1.2 token"
        };
        amount= 0n;
      };
      foreign_tokens = (Map.empty: MarketMaker.token_amount_map);
    });
    ("BTCtz", {
      total_shares = 0n;
      holdings = (Set.empty: nat set);
      native_token = {
        token = {
          token_id = 0n;
          name = "BTCtz";
          address = Some(("KT1ErLEYVsxqHxLgLucXViq5DYrtSyDuSFTe" : address));
          decimals = 8n;
          standard = Some "FA2 token"
        };
        amount= 0n;
      };
      foreign_tokens = (Map.empty: MarketMaker.token_amount_map);
    });
    ("EURL", {
      total_shares = 0n;
      holdings = (Set.empty: nat set);
      native_token = {
        token = {
          token_id = 0n;
          name = "EURL";
          address = Some(("KT1RcHjqDWWycYQGrz4KBYoGZSMmMuVpkmuS" : address));
          decimals = 6n;
          standard = Some "FA2 token"
        };
        amount= 0n;
      };
      foreign_tokens = (Map.empty: MarketMaker.token_amount_map);
    });
    ("USDtz", {
      total_shares = 0n;
      holdings = (Set.empty: nat set);
      native_token = {
        token = {
          token_id = 0n;
          name = "USDtz";
          address = Some(("KT1B8tP5Q8Cb7HctLfxt4MVk2cWouHFrnbjW" : address));
          decimals = 6n;
          standard = Some "FA1.2 token"
        };
        amount= 0n;
      };
      foreign_tokens = (Map.empty: MarketMaker.token_amount_map);
    });
    ("USDT", {
      total_shares = 0n;
      holdings = (Set.empty: nat set);
      native_token = {
        token = {
          token_id = 0n;
          name = "USDT";
          address = Some(("KT1WNrZ7pEbpmYBGPib1e7UVCeC6GA6TkJYR" : address));
          decimals = 6n;
          standard = Some "FA2 token"
        };
        amount= 0n;
      };
      foreign_tokens = (Map.empty: MarketMaker.token_amount_map);
    })
  ];
  limit_on_tokens_or_pairs = 10n;
  last_holding_id = 0n;
  user_holdings = (Big_map.empty: MarketMaker.user_holdings);
  vault_holdings = (Big_map.empty: MarketMaker.vault_holdings);
}