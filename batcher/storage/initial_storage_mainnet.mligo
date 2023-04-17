#import "../batcher.mligo" "Batcher"

let f(_:unit) : Batcher.Storage.t = {
  metadata = (Big_map.empty : Batcher.metadata);
  valid_tokens = Map.literal [
    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("EURL"),{
      token_id = 0n;
      name = "EURL";
      address = Some(("KT1JBNFcB5tiycHNdYGYCtR3kk6JaJysUCi8" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      token_id = 0n;
      name = "USDT";
      address = Some(("tz1N47UGiVScUUvHemXd2kGwJi44h7qZMUzp" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    })
  ];
  valid_swaps = Map.literal [
    ("tzBTC/USDT", {
        swap = {
            from = {
              amount = 1n;
              token = {
                token_id = 0n;
                name = "tzBTC";
                address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
                decimals = 8n;
                standard = Some "FA1.2 token"
              }
            };
            to = {
              token_id = 0n;
              name = "USDT";
              address = Some(("tz1N47UGiVScUUvHemXd2kGwJi44h7qZMUzp" : address));
              decimals = 6n;
              standard = Some "FA2 token";
            }
        };
        oracle_address = ("": address);
        oracle_asset_name = "tzBTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("EURL/tzBTC", {
        swap = {
          from = {
            amount = 1n;
            token = {
              token_id = 0n;
              name = "tzBTC";
              address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
              decimals = 8n;
              standard = Some "FA1.2 token";
            }
          };
          to = {
            token_id = 0n;
            name = "EURL";
            address = Some(("KT1JBNFcB5tiycHNdYGYCtR3kk6JaJysUCi8" : address));
            decimals = 6n;
            standard = Some "FA2 token";
          }
        };
        oracle_address = ("KT1KcFDLDt1bFWnZVeWL6tB4tMwi2WMQwgU2": address);
        oracle_asset_name = "tzBTC-EURL";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  rates_current = (Big_map.empty : Batcher.Storage.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
   	batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address);
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
  scale_factor_for_oracle_staleness = 1n

}

