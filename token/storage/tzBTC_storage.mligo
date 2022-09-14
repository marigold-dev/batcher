let f (_:unit) = {
  ledger = Big_map.literal [
    ((("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address), 0n), 1000n)
  ];
  token_metadata = Big_map.literal [
    (0n, {
      token_id = 0n;
      token_info = Map.literal [
        ("", ("68747470733a2f2f676973742e67697468756275736572636f6e74656e742e636f6d2f6b69656e6c653337313939392f65633161333338616632623137366365336433656462316133653036366261662f7261772f373263666338356138303834303136633333343437333837633062613637616664666165636666622f747a4254432e6a736f6e" : bytes))
      ]
    })
  ];
  operators = (Big_map.empty : ((address * address), nat set) big_map)
}