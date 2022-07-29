#import "types.mligo" "CommonTypes"


module Types struct
 (* The tokens that are valid within the contract  *)
 type valid_tokens = CommonTypes.token list

 (* The swaps of valid tokens that are accepted by the contract  *)
 type valid_swaps =  CommonTypes.swap list

 (* The current, most up to date exchange rates between tokens  *)
 type rates_current = (CommonTypes.swap, CommonTypes.exchange_rate) big_map

 (* Historical rates for the contract - this can be a limited set after the PoC. i.e. last day or week *)
 type rates_historic = (CommonTypes.swap, CommonTypes.exchange_rate list) big_map



  type t = {
    valid_tokens : valid_tokens;
    valid_swaps : valid_swaps;
    rates_current : rates_current;
    rates_historic : rates_historic;
  }

end
