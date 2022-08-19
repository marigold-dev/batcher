{
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
    ("XTZ/USDT", {
      to =     {
       name = "XTZ";
       address = (None : address option);
    };
    from = {
      name = "USDT";
      address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
    }
    } );
    ("USDT/tzBTC", {
      to = {
      name = "USDT";
      address = Some(("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address));
      } ;
      from = {
       name = "tzBTC";
       address = Some(("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address));
      }
    } )
  ];
  rates_current = (Big_map.empty : CommonStorage.Types.rates_current);
  rates_historic = (Big_map.empty : CommonStorage.Types.rates_historic);
}
