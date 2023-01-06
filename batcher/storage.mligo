#import "types.mligo" "CommonTypes"

module Types = struct
  (* The tokens that are valid within the contract  *)
  type valid_tokens = CommonTypes.Types.token list

  (* The swaps of valid tokens that are accepted by the contract  *)
  type valid_swaps =  (string, CommonTypes.Types.swap) map

  (* The current, most up to date exchange rates between tokens  *)
  type rates_current = (string, CommonTypes.Types.exchange_rate) big_map

  type batch = CommonTypes.Types.batch

  type batch_set = CommonTypes.Types.batch_set

  type orderbook = CommonTypes.Types.orderbook


  type user_batch_ordertypes = CommonTypes.Types.user_batch_ordertypes

  type t = {
    [@layout:comb]
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    rates_current : rates_current;
    batch_set : batch_set;
    orderbook : orderbook;
    last_order_number : nat;
    user_batch_ordertypes: user_batch_ordertypes
  }

end
