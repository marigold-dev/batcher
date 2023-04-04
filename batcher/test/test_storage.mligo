#import "../batcher.mligo" "Batcher"
#import "../breathalyzer/lib/lib.mligo" "Breath"
#import "../math-lib-cameligo/rational/rational.mligo" "Rational"
#import "test_mock_oracle.mligo" "Oracle"

type level = Breath.Logger.level
type storage = Batcher.Storage.t
type oracle_storage = Oracle.storage

let initial_storage
    (oracle_address: address)  : storage = {  
    metadata = (Big_map.empty : (string,bytes) big_map);
    valid_tokens = Map.literal [
      (("tzBTC"), {
        name = "tzBTC";
        address = Some(("KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG" : address));
        decimals = 8n;
        standard = Some "FA1.2 token";
      });
      (("EURL"),{
        name = "EURL";
        address = Some(("KT1UhjCszVyY5dkNUXFGAwdNcVgVe2ZeuPv5" : address));
        decimals = 6n;
        standard = Some "FA2 token";
      });
      (("USDT"),{
        name = "USDT";
        address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
        decimals = 6n;
        standard = Some "FA2 token";
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
                  standard = Some "FA1.2 token";
                };
              };
              to = {
                name = "USDT";
                address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
                decimals = 6n;
                standard = Some "FA2 token";
              }
          };
          oracle_address = oracle_address;
          oracle_asset_name = "tzBTC-USDT";
          oracle_precision = 6n;
          is_disabled_for_deposits = false;
        }
      );
      ("EURL/tzBTC", {
          swap = {
            from = {
              amount = 1n;
              token = {
                name = "tzBTC";
                address = Some(("KT1XLyXAe5FWMHnoWa98xZqgDUyyRms2B3tG" : address));
                decimals = 8n;
                standard = Some "FA1.2 token";
              };
            };
            to = {
              name = "EURL";
              address = Some(("KT1UhjCszVyY5dkNUXFGAwdNcVgVe2ZeuPv5" : address));
              decimals = 6n;
              standard = Some "FA2 token";
            }
          };
          oracle_address = oracle_address;
          oracle_asset_name = "tzBTC-EURL";
          oracle_precision = 6n;
          is_disabled_for_deposits = false;
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
    deposit_time_window_in_seconds = 600n
}

module Helpers = struct

let expect_from_storage
  (type a)
  (name: string)
  (storage: storage)
  (selector: storage -> a)
  (expected_value: a) = Breath.Assert.is_equal name (selector storage) expected_value

let expect_last_order_number
  (storage: storage)
  (last_order_number: nat)  = expect_from_storage "last_order_number" storage (fun s -> s.last_order_number) last_order_number

let expect_rate_value
  (storage: storage)
  (rate_name: string)
  (rate: Rational.t)  =
  match Big_map.find_opt rate_name storage.rates_current with
  | None -> Breath.Assert.fail_with "Could not find rate in storage"
  | Some r -> Breath.Assert.is_equal "rate value" r.rate rate
  
let expect_oracle_value
  (storage: oracle_storage)
  (value: nat)  =
  match storage with
  | None -> Breath.Assert.fail_with "Oracle doesn't contain a rate"
  | Some s -> Breath.Assert.is_equal "oracle value" s.value value
 
end 
