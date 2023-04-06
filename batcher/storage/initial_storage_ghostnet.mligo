#import "../batcher.mligo" "Batcher"

let f(_:unit) : Batcher.Storage.t = {
  metadata = (Big_map.empty : Batcher.metadata);
  valid_tokens = Map.literal [
    (("tzBTC"), {
      name = "tzBTC";
      address = Some(("KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG" : address));
      decimals = 8n;
      standard = Some "FA1.2 token"
    });
    (("EURL"),{
      name = "EURL";
      address = Some(("KT1UhjCszVyY5dkNUXFGAwdNcVgVe2ZeuPv5" : address));
      decimals = 6n;
      standard = Some "FA2 token"
    });
    (("USDT"),{
      name = "USDT";
      address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
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
                name = "tzBTC";
                address = Some(("KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG" : address));
                decimals = 8n;
                standard = Some "FA1.2 token"
              }
            };
            to = {
              name = "USDT";
              address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
              decimals = 6n;
              standard = Some "FA2 token";
            }
        };
        oracle_address = ("KT1NyTjT9mdtiK1fTF9Wwgkb1A6nDWFRRezy": address);
        oracle_asset_name = "BTC-USDT";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    );
    ("tzBTC/EURL", {
        swap = {
          from = {
            amount = 1n;
            token = {
              name = "tzBTC";
              address = Some(("KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG" : address));
              decimals = 8n;
              standard = Some "FA1.2 token";
            }
          };
          to = {
            name = "EURL";
            address = Some(("KT1UhjCszVyY5dkNUXFGAwdNcVgVe2ZeuPv5" : address));
            decimals = 6n;
            standard = Some "FA2 token";
          }
        };
        oracle_address = ("KT1NyTjT9mdtiK1fTF9Wwgkb1A6nDWFRRezy": address);
        oracle_asset_name = "BTC-EUR";
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

