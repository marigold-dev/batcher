#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = [
    {
       name = "tzBTC";
       address = Some(("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr" : address));
       decimals = 8;
    };
    {
      name = "USDT";
      address = Some(("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF" : address));
       decimals = 6;
    };
    {
       name = "XTZ";
       address = (None : address option);
       decimals = 6;
    }
  ];
  valid_swaps = Map.literal [
    ("USDT/tzBTC", {
        from = {
          token = {
            name = "tzBTC";
            address = Some(("KT1XBUuCDb7ruPcLCpHz4vrh9jL9ogRFYTpr" : address));
            decimals = 8;
          };
          amount = 10n;
        };
        to = {
          name = "USDT";
          address = Some(("KT1AqXVEApbizK6ko4RqtCVdgw8CQd1xaLsF" : address));
          decimals = 6;
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

