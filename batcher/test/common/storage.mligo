#import "../../batcher.mligo" "Batcher"
#import "ligo-breathalyzer/lib/lib.mligo" "Breath"
#import "@ligo/math-lib/rational/rational.mligo" "Rational"

type level = Breath.Logger.level
type storage = Batcher.Storage.t

let btc_address = ("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address)
let usdt_address = ("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address)
let eurl_address = ("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address)


let initial_storage : storage = {
  metadata = (Big_map.empty : Batcher.metadata);
  valid_tokens = Map.literal [
    (("tzBTC"), {
      token_id = 0n;
      name = "tzBTC";
      address = Some(btc_address);
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
  rates_current = (Big_map.empty : Batcher.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
   	batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address);
  administrator = ("tz1aSL2gjFnfh96Xf1Zp4T36LxbzKuzyvVJ4" : address);
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
  scale_factor_for_oracle_staleness = 1n
}

let expect_from_storage
  (type a)
  (name: string)
  (storage: storage)
  (selector: storage -> a)
  (expected_value: a) = Breath.Assert.is_equal name (selector storage) expected_value

