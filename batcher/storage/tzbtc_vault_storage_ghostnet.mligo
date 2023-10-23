#import "../vault.mligo" "Vault"
#import "../types.mligo" "Types"
let f(_:unit) : Vault.Vault.storage = {
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  batcher = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  marketmaker = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  tokenmanager = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  total_shares = 0n;
  native_token = {
  token = {
      token_id = 0n;
      name = "tzBTC";
      address = Some(("KT1P8RdJ5MfHMK5phKJ5JsfNfask5v2b2NQS" : address));
      decimals = 8n;
      standard = Some "FA1.2 token"
    };
    amount = 0n;
    };
  foreign_tokens = (Map.empty:(string, Vault.token_amount) map );
  vault_holdings = Types.VaultHoldings.empty ;
}

