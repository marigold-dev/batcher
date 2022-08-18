

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

  type exchange_rate = {
     [@layout:comb]
     swap : swap;
     rate: tez;
     when : timestamp;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    tolerance : tolerance;
    created_at : timestamp;
  }

  (*This type represent a result of a match computation, we can partially or totally match two orders*)
  type match_result = Total | Partial of swap_order
end


module Utils = struct


  let get_rate_name_from_swap (s : Types.swap) : string =
    let quote_name = s.to.name in
    let base_name = s.from.token.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let quote_name = r.swap.to.name in
    let base_name = r.swap.from.token.name in
    quote_name ^ "/" ^ base_name

end

