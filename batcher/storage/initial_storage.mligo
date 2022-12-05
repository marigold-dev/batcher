#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = [
    {
      name = "tzBTC";
      address = Some(("KT1FRyR3ohQ59N54BJMg9KjDUGh4z5hWuYab" : address));
      decimals = 8;
      standard = Some "FA1.2 token";
    };
    {
      name = "USDT";
      address = Some(("KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF" : address));
      decimals = 6;
      standard = Some "FA2 token";
    };
    {
      name = "XTZ";
      address = (None : address option);
      decimals = 6;
      standard = None;
    }
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
  user_orderbook = (Big_map.empty : (address, Storage.Types.user_orders) big_map);
  batch_set = {
     current_batch_number =  0n;
     last_batch_number = 0n;
   	 batches = (Big_map.empty : (nat,Storage.Types.batch) big_map);
  };
}

