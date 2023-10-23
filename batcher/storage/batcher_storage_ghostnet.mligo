#import "../batcher.mligo" "Batcher"
let meta : bytes =
  0x68747470733a2f2f697066732e6763702e6d617269676f6c642e6465762f697066732f516d56375a534b6358324d4e75656938745a3268723555484d5a66737039476b375675345878766d6246734a4e45

let f(_:unit) : Batcher.Storage.t = {
  metadata = (Big_map.empty : Batcher.metadata);
  rates_current = (Big_map.empty : Batcher.rates_current);
  batch_set = {
    current_batch_indices = (Map.empty : (string,nat) map);
   	batches = (Big_map.empty : (nat,Batcher.batch) big_map);
  };
  last_order_number = 0n;
  user_batch_ordertypes = (Big_map.empty: Batcher.user_batch_ordertypes);
  fee_in_mutez = 10_000mutez;
  fee_recipient = ("tz1burnburnburnburnburnburnburjAYjjX" :  address);
  administrator = ("tz1ca4batAsNxMYab3mUK5H4QRjY8drV4ViL" : address);
  marketmaker = ("KT1XKvKiTTj8N6WKv3MhnZhFjZopFGQGBTdT" : address);
  tokenmanager = ("KT19JLvQdDGUnssfL5n6rBozZpnaej3Xfvjy" : address);
  limit_on_tokens_or_pairs = 10n;
  deposit_time_window_in_seconds = 600n;
}
