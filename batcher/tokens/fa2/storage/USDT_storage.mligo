let f (_:unit) = {
  ledger = Big_map.literal [
    ((("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 0n), 10000000000000n)
  ];
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f676c6f74746f6c6f676973742f63633262366133396336663436313361393039623932356365653163353435362f7261772f343465373561386162633431623361336264636366323162663666373862393461313238653631312f555344542e6a736f6e" : bytes))
      ]
    })
  ];
  operators = (Big_map.empty : ((address * address), nat set) big_map)
}
