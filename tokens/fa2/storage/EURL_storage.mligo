let f (_:unit) = {
  ledger = Big_map.literal [
    ((("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 0n), 10000000000000n)
  ];
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f62306130323531313666666365616335656533313066656133396365343430332f7261772f346437623833383033373537346535363065353461363363356364626665303633663762653964322f4555524c2e6a736f6e" : bytes))
      ]
    })
  ];
  operators = (Big_map.empty : ((address * address), nat set) big_map)
}
