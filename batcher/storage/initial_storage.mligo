#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = [
    {
      name = "tzBTC";
      address = Some(("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr" : address));
      decimals = 8;
      standard = Some "FA1.2 token";
    };
    {
      name = "USDT";
      address = Some(("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF" : address));
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
            address = Some(("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr" : address));
            decimals = 8;
            standard = Some "FA1.2 token";
          };
        };
        to = {
          name = "USDT";
          address = Some(("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF" : address));
          decimals = 6;
          standard = Some "FA2 token";
        }
      }
    )
  ];
  rates_current = (Big_map.empty : Storage.Types.rates_current);
  batches = {
     current = (None : Storage.Types.batch option);
   	 previous = ([] : Storage.Types.batch list);
  };
}

