{
  ledger = Big_map.literal [
    ((("tz1aSkwEot3L2kmUvcoxzjMomb9mvBNuzFK6" : address), 0n), 500n)
  ];
  token_metadata = Big_map.literal [
    (0n, { 
      token_id = 0n;
      token_info = Map.literal [
        ("", ("697066733a2f2f516d6272624a6b586148336f567654374e3563647338746859687771786658706e6258444d6b725332564772454a" : bytes))
      ];
    })
  ];
  operators = (Big_map.empty : Operators.t);
}