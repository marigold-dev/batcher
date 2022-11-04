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
  total_supply = 100000000000n;
}
