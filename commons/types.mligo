

module Types = struct

  (* Associate alias to token address *)
  type token = {
    [@layout:comb]
    name : string;
    address : address option;
  }

  (* A token value ascribes an amount to token metadata *)
  type token_amount = {
     [@layout:comb]
     token : token;
     amount : nat;
  }

  (* Price associates a timestamp to a token value to fix in time *)
  type token_price = {
     [@layout:comb]
     token : token;
     value : nat;
     when : timestamp;
  }

  type exchange_rate = {
     [@layout:comb]
     quote : token_price;
     base : token_price;
  }

  type swap = {
   from : token;
   to : token;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    from_amount : nat;
    to_price : nat;
    tolerance : nat;
    deadline : timestamp;
  }

  type deposit = {
    deposited_token : token_amount;
    exchange_rate : exchange_rate;
  }

  type redeem = {
    redeemed_token : token_amount;
    exchange_rate : exchange_rate;
  }

end


module Utils = struct

  let get_token_name_from_price (t : Types.token_price) = t.token.name

  let get_rate_name_from_swap (s : Types.swap) : string =
    let quote_name = s.to.name in
    let base_name = s.from.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let quote_name = get_token_name_from_price (r.quote) in
    let base_name = get_token_name_from_price (r.quote) in
    quote_name ^ "/" ^ base_name

end

