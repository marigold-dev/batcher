#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = Map.literal [
    ("tzBTC", {
      name = "tzBTC";
      address = Some(("KT1FRyR3ohQ59N54BJMg9KjDUGh4z5hWuYab" : address));
      decimals = 8;
      standard = Some "FA1.2 token";
    }),
    ("USDT",{
      name = "USDT";
      address = Some(("KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF" : address));
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
            address = Some(("KT1FRyR3ohQ59N54BJMg9KjDUGh4z5hWuYab" : address));
            decimals = 8;
            standard = Some "FA1.2 token";
          };
        };
        to = {
          name = "USDT";
          address = Some(("KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF" : address));
          decimals = 6;
          standard = Some "FA2 token";
        }
      }
    )
  ];
  rates_current = (Big_map.empty : Storage.Types.rates_current);
  orderbook = (Big_map.empty : Storage.Types.orderbook);
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Storage.Types.user_batch_ordertypes);
  batch_set = {
    current_batch_index =  0n;
    current_batch_status =  2n;
   	batches = (Big_map.empty : (nat,Storage.Types.batch) big_map);
  };
}

