
#import "../batcher.mligo" "Batcher"

let meta:bytes = 0x68747470733a2f2f697066732e6763702e6d617269676f6c642e6465762f697066732f516d56375a534b6358324d4e75656938745a3268723555484d5a66737039476b375675345878766d6246734a4e45

let f(_:unit) : Batcher.Storage.t = {
  metadata = Big_map.literal [
   ("",meta)
  ]; 
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
      address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
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
              address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
              decimals = 6n;
              standard = Some "FA2 token";
            }
        };
        oracle_address = ("KT1EhS7KVk6cAaYjUpg4jM1VjPGLJTrT9vqG": address);
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
        oracle_address = ("KT1EhS7KVk6cAaYjUpg4jM1VjPGLJTrT9vqG": address);
        oracle_asset_name = "BTC-EUR";
        oracle_precision = 6n;
        is_disabled_for_deposits = false
      }
    )
  ];
  rates_current = (Big_map.empty : Batcher.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
   	batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address);
  administrator = ("tz1ftWawLjmm6poX3R73Xc1UaFRoucCSpnhf" : address);
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
  scale_factor_for_oracle_staleness = 1n

}


