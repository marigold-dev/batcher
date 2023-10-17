#import "../marketmaker.mligo" "MarketMaker"

let f(_:unit) : MarketMaker.MarketMaker.storage = {
  batcher = ("KT1LhTpwSGcFAUUM3JYjW8XW74UHP82YzERy" :  address);
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  tokenmanager = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  vaults = {
  keys = (Set.empty: string set);
  values = (Big_map.empty:  (string,address) big_map);
  };
}
