type allowance_key =
  [@layout:comb] {
    owner : address;
    spender : address 
  }


let f (_:unit) = {
  tokens = Big_map.literal [
    (("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 10000000000000n)
  ];
  allowances = (Big_map.empty : (allowance_key, nat) big_map);
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f6b69656e6c653337313939392f36323931343834363337636166343239393062633136363162353562373735642f7261772f303137333038393937383361363237313562656530303537323532343632366563623630356662382f666131325f747a4254432e6a736f6e" : bytes))
      ]
    })
  ];
  total_supply = 100000000000n;
}
