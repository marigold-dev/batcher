let f(_:unit) = {
  valid_tokens = [
    {
       name = "tzBTC";
       address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
    };
    {
      name = "USDT";
      address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
    };
    {
       name = "XTZ";
       address = (None : address option);
    }
  ];
  valid_swaps = Map.literal [
    ("USDT/tzBTC", {
        from = {
          token = {
            name = "tzBTC";
            address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
          };
          amount = 10n;
        };
        to = {
          name = "USDT";
          address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
        }
      }
    )
  ];
  rates_current = (Big_map.empty : Storage.Types.rates_current);
  rates_historic = (Big_map.empty : Storage.Types.rates_historic);
  batches = {
     current = (None : Storage.Types.batch option);
   	 previous = ([] : Storage.Types.batch list);
  };
}

