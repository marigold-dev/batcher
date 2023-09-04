
#import "../batcher.mligo" "Batcher"

let f(_:unit) : Batcher.Storage.t = {
  metadata = Big_map.literal [
   ("",("011010000111010001110100011100000111001100111010001011110010111101101001011100000110011001110011001011100110011101100011011100000010111001101101011000010111001001101001011001110110111101101100011001000010111001100100011001010111011000101111011010010111000001100110011100110010111101010001011011010101011000110111010110100101001101001011011000110101100000110010010011010100111001110101011001010110100100111000011101000101101000110010011010000111001000110101010101010100100001001101010110100110011001110011011100000011100101000111011010110011011101010110011101010011010001011000011110000111011001101101011000100100011001110011010010100100111001000101":bytes) )
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
  rates_current = (Big_map.empty : Batcher.Storage.rates_current);
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


