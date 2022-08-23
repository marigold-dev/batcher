#import "constants.mligo" "Constants"

module Types = struct

  (* Associate alias to token address *)
  type token = {
    [@layout:comb]
    name : string;
    address : address option;
  }

  (* Side of an order, either BUY side or SELL side  *)
  type side = BUY | SELL

  (* Tolerance of the order against the oracle price  *)
  type tolerance = PLUS | EXACT | MINUS

  (* A token value ascribes an amount to token metadata *)
  type token_amount = {
     [@layout:comb]
     token : token;
     amount : nat;
  }


  type swap = {
   from : token_amount;
   to : token;
  }

  (*I change the type of the rate from tez to nat for sake of simplicity*)
  type exchange_rate = {
    [@layout:comb]
    swap : swap;
    rate: nat;
    when : timestamp;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    created_at : timestamp;
    side : side;
    tolerance : tolerance;
  }

  type clearing = {
    clearing_volumes : (tolerance, nat)  map;
    clearing_tolerance : tolerance;
  }

  (*This type represent a result of a match computation, we can partially or totally match two orders*)
  type match_result = Total | Partial of swap_order

  type treasury_item_status = DEPOSITED | EXCHANGED | CLAIMED

  type treasury = (address, token_amount) big_map
end

module Utils = struct
  let get_rate_name_from_swap (s : Types.swap) : string =
    let quote_name = s.to.name in
    let base_name = s.from.token.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name_from_pair (s : Types.token * Types.token) : string =
    let (quote, base) = s in
    let quote_name = quote.name in
    let base_name = base.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let quote_name = r.swap.to.name in
    let base_name = r.swap.from.token.name in
    quote_name ^ "/" ^ base_name

  let pair_of_swap (order : Types.swap) : (Types.token * Types.token) =
    (order.from.token, order.to)
end

