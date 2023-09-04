#import "../batcher.mligo" "Batcher"

let f(_:unit) : Batcher.Storage.t = {
  metadata = Big_map.literal [
   ("",("01101000011101000111010001110000011100110011101000101111001011110110100101110000011001100111001100101110011010010110111100101111011010010111000001100110011100110010111101010001011011010101011000110111010110100101001101001011011000110101100000110010010011010100111001110101011001010110100100111000011101000101101000110010011010000111001000110101010101010100100001001101010110100110011001110011011100000011100101000111011010110011011101010110011101010011010001011000011110000111011001101101011000100100011001110011010010100100111001000101":bytes) )
   ];
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
            from = {
              amount = 1n;
              token = {
                token_id = 0n; 
                name = "tzBTC";
                address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
                decimals = 8n;
                standard = Some "FA1.2 token"
              }
            };
            to = {
              token_id = 0n; 
              name = "USDT";
              address = Some(("KT1WNrZ7pEbpmYBGPib1e7UVCeC6GA6TkJYR" : address));
              decimals = 6n;
              standard = Some "FA2 token";
            }
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
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
              address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
              decimals = 8n;
              standard = Some "FA1.2 token";
            }
          };
          to = {
            token_id = 0n; 
            name = "EURL";
            address = Some(("KT1RcHjqDWWycYQGrz4KBYoGZSMmMuVpkmuS" : address));
            decimals = 6n;
            standard = Some "FA2 token";
          }
        };
        oracle_address = ("KT1DG2g5DPYWqyHKGpRL579YkYZwJxibwaAZ": address);
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


