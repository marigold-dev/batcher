type allowance_key =
  [@layout:comb] {
    owner : address;
    spender : address 
  }


let f (_:unit) = {
  tokens = Big_map.literal [
    (("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 100000000000n)
  ];
  allowances = (Big_map.empty : (allowance_key, nat) big_map);
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f65653736383665633638376339336131656666653331666362306131343734362f7261772f303232666332646462653534346631363466343431356266633139613131663135376630303562332f545a4254432e6a736f6e" : bytes))
      ]
    })
  ];
  total_supply = 10000000000000n;
}
