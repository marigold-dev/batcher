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
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f63613566383738393764613266636432333364633131313732343231346239622f7261772f376433623864303665323465373161386330393065666336373836306237633562333439306361622f6374657a2e6a736f6e" : bytes))
      ]
    })
  ];
  total_supply = 10000000000000n;
}
