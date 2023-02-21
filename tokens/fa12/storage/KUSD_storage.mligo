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
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f38323132383634366339363738396530336437333961303563376563353932362f7261772f386234356263616164666337383338306266643964353231613465633938363831653339636630652f4b5553442e6a736f6e" : bytes))
      ]
    })
  ];
  total_supply = 10000000000000n;
}
