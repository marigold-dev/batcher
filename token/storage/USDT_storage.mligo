let f (_:unit) = {
  ledger = Big_map.literal [
    ((("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 0n), 100000000n)
  ];
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f6b69656e6c653337313939392f62626634333863366131626338323931313539383265373165636664396266612f7261772f386133383966633764316135623837343437376238613731663432316661396261303337333238622f555344542e6a736f6e" : bytes))
      ]
    })
  ];
  operators = (Big_map.empty : ((address * address), nat set) big_map)
}