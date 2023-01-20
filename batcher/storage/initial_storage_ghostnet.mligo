#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = Map.literal [
    (("tzBTC"), {
      name = "tzBTC";
      address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
      decimals = 8;
      standard = Some "FA1.2 token";
    });
    (("USDT"),{
      name = "USDT";
      address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
      decimals = 6;
      standard = Some "FA2 token";
    })
  ];
  valid_swaps = Map.literal [
    ("tzBTC/USDT", {
        from = {
          amount = 1n;
          token = {
            name = "tzBTC";
            address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
            decimals = 8;
            standard = Some "FA1.2 token";
          };
        };
        to = {
          name = "USDT";
          address = Some(("KT1H9hKtcqcMHuCoaisu8Qy7wutoUPFELcLm" : address));
          decimals = 6;
          standard = Some "FA2 token";
        }
      }
    )
  ];
  rates_current = (Big_map.empty : Storage.Types.rates_current);
  batch_set = {
    current_batch_index = 0n;
   	batches = (Big_map.empty : (nat,Storage.Types.batch) big_map);
  };
  orderbook = (Big_map.empty : Storage.Types.orderbook);
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Storage.Types.user_batch_ordertypes);
}

