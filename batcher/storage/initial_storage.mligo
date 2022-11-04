#import "../storage.mligo" "Storage"

let f(_:unit) = {
  valid_tokens = [
    {
      name = "tzBTC";
      address = Some(("KT1ADYfLrrifqZZGMpgtZF2HkEhNfDXXsdSK" : address));
      decimals = 8;
    };
    {
      name = "USDT";
      address = Some(("KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF" : address));
      decimals = 6;
    };
    {
      name = "XTZ";
      address = (None : address option);
      decimals = 6;
    }
  ];
  valid_swaps = Map.literal [
    ("tzBTC/USDT", {
        from = {
          amount = 1n;
          token = {
            name = "tzBTC";
            address = Some(("KT1ADYfLrrifqZZGMpgtZF2HkEhNfDXXsdSK" : address));
            decimals = 8;
          };
        };
        to = {
          name = "USDT";
          address = Some(("KT1QVV45Rj9r6WbjLczoDxViP9s1JpiCsxVF" : address));
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

