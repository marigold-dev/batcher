{
  valid_tokens = [
    {
       name = "XTZ";
       address = ("0" : address);
    },
    {
       name = "tzBTC";
       address = ("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address);
    },
    {
      name = "USDT";
      address = ("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address);
    }
  ];
  valid_swaps = Map.literal [
    ("XTZ/USDT", {
      to =     {
       name = "XTZ";
       address = ("0" : address);
    };
    from = {
      name = "USDT";
      address = ("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address);
    }
    } );
    ("USDT/tzBTC", {
      to = {
      name = "USDT";
      address = ("KT1XnTn74bUtxHfDtBmm2bGZAQfhPbvKWR8o" : address);
      } ;
      from = {
       name = "tzBTC";
       address = ("KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn" : address);
      }
    } )
  ];
  rates_current = (Big_map.empty : CommonStorage.Types.rates_current);
  rates_historic = (Big_map.empty : CommonStorage.Types.rates_historic);

}
