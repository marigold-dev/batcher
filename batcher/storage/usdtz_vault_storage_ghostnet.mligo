#import "../vault.mligo" "Vault"
let f(_:unit) : Vault.Vault.storage = {
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  batcher = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  marketmaker = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  tokenmanager = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  total_shares = 0n;
  native_token = {
  token = {
      token_id = 0n;
      name = "USDtz";
      address = Some(("KT1B8tP5Q8Cb7HctLfxt4MVk2cWouHFrnbjW" : address));
      decimals = 6n;
      standard = Some "FA1.2 token"
    };
    amount = 0n;
    };
  foreign_tokens = (Map.empty:(string, Vault.token_amount) map );
  vault_holdings = (Big_map.empty: (address, Vault.vault_holding) big_map);
}

