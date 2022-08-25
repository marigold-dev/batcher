#import "types.mligo" "CommonTypes"
#import "batch.mligo" "Batch"
#import "order.mligo" "Order"

module Types = struct
  (* The tokens that are valid within the contract  *)
  type valid_tokens = CommonTypes.Types.token list

  (* The swaps of valid tokens that are accepted by the contract  *)
  type valid_swaps =  (string, CommonTypes.Types.swap) map

  (* The current, most up to date exchange rates between tokens  *)
  type rates_current = (string, CommonTypes.Types.exchange_rate) big_map

  (* Historical rates for the contract - this can be a limited set after the PoC. i.e. last day or week *)
  type rates_historic = (string, CommonTypes.Types.exchange_rate list) big_map

  type t = {
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    rates_current : rates_current;
    rates_historic : rates_historic;
    treasury: CommonTypes.Types.treasury;
    batches : Batch.batch_set;
    orders : Order.t
  }

end
