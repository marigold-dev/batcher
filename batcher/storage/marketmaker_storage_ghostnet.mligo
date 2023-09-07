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
  batcher = ("tz1burnburnburnburnburnburnburjAYjjX" :  address);
  administrator = ("tz1aSL2gjFnfh96Xf1Zp4T36LxbzKuzyvVJ4" : address);
  vaults = (Big_map.empty: MarketMaker.market_vaults);
  limit_on_tokens_or_pairs = 10n;
  last_holding_id = 0n;
  user_holdings = (Big_map.empty: MarketMaker.user_holdings);
  vault_holdings = (Big_map.empty: MarketMaker.vault_holdings);
}
