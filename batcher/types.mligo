#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/float.mligo" "Float"

module Types = struct

  (* Associate alias to token address *)
  type token = {
    name : string;
    address : address option;
    decimals : int;
    standard : string option;
  }

  (* Side of an order, either BUY side or SELL side  *)
  type side =
    [@layout:comb]
    BUY
    | SELL

  (* Tolerance of the order against the oracle price  *)
  type tolerance =
    PLUS | EXACT | MINUS

  (* A token value ascribes an amount to token metadata *)
  type token_amount = {
    token : token;
    amount : nat;
  }

  type token_amount_map = (string, token_amount) map

  type token_holding_map = (address, token_amount_map) map


  (* A token amount 'held' by a specific address *)
  type token_holding = {
    holder: address;
    token_amount : token_amount;
    redeemed: bool;
  }

  type swap = {
   from : token_amount;
   to : token;
  }

  (*I change the type of the rate from tez to nat for sake of simplicity*)
  type exchange_rate = {
    swap : swap;
    rate: Float.t;
    when : timestamp;
  }

  type swap_order = {
    order_number: nat;
    batch_number: nat;
    trader : address;
    swap  : swap;
    created_at : timestamp;
    side : side;
    tolerance : tolerance;
    redeemed:bool;
  }

  type external_swap_order = {
    swap  : swap;
    created_at : timestamp;
    side : nat;
    tolerance : nat;
  }

  type batch_status  =
    NOT_OPEN | OPEN | CLOSED | FINALIZED

  type prorata_equivalence = {
    buy_side_actual_volume: nat;
    buy_side_actual_volume_equivalence: nat;
    sell_side_actual_volume: nat;
    sell_side_actual_volume_equivalence: nat
  }

  type clearing_volumes = {
    minus: nat;
    exact: nat;
    plus: nat;
  }


  type clearing = {
    clearing_volumes : clearing_volumes;
    clearing_tolerance : tolerance;
    prorata_equivalence: prorata_equivalence;
    clearing_rate: exchange_rate;
  }


  (* These types are used in math module *)
  type buy_minus_token = int
  type buy_exact_token = int
  type buy_plus_token = int
  type buy_side = buy_minus_token * buy_exact_token * buy_plus_token

  type sell_minus_token = int
  type sell_exact_token = int
  type sell_plus_token = int
  type sell_side = sell_minus_token * sell_exact_token * sell_plus_token

  (*
    A bid : the price a buyer is willing to pay for an asset
    A ask : the price a seller is willing to auxept for an asset
    Here, the orderbook is a map of bids orders list  and asks order list
  *)
  type orderbook = (nat, swap_order) big_map

  type batch_status =
    | Open of { start_time : timestamp }
    | Closed of { start_time : timestamp ; closing_time : timestamp }
    | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }


  type volumes = {
    [@layout:comb]
    buy_minus_volume : nat;
    buy_exact_volume : nat;
    buy_plus_volume : nat;
    sell_minus_volume : nat;
    sell_exact_volume : nat;
    sell_plus_volume : nat;
  }

  type pair = token * token

  (* This represents the type of order.  I.e. buy/sell and which level*)
  type ordertype = {
     side: side;
     tolerance: tolerance;
  }

  (* Mapping order type to total amount of placed orders  *)
  type ordertypes = (ordertype, nat) map

  (* pairing of batch_id and ordertypes. *)
  type batch_ordertypes = (nat,  ordertypes) map

  (* Associated user address to a given set of batches and ordertypes  *)
  type user_batch_ordertypes = (address, batch_ordertypes) big_map


  (* Batch of orders for the same pair of tokens *)
  type batch = {
    batch_number: nat;
    status : batch_status;
    volumes : volumes;
    pair : pair;
  }

  (* Set of batches, containing the current batch and the previous (finalized) batches.
     The current batch can be open for deposits, closed for deposits (awaiting clearing) or
     finalized, as we wait for a new deposit to start a new batch *)
  type batch_set = {
    current_batch_number: nat;
    last_batch_number: nat;
    batches: (nat, batch) big_map;
    }
end

module TokenAmount = struct

  type t = Types.token_amount

  let recover
  (ot: Types.ordertype)
  (amt: nat)
  (c: Types.clearing): t =
  let swap = c.clearing_rate.swap in
  let token = match ot.side with
             | BUY -> swap.from.token
             | SELL -> swap.to
  in
  {
    token = token;
    amount = amt;
  }


end

module TokenAmountMap = struct

  type t = Types.token_amount_map

  type op = INCREASE | DECREASE

  let amend
  (ta: Types.token_amount)
  (op: op)
  (tam : t): t =
  let token_name = ta.token.name in
  match Map.find_opt token_name tam with
  | None -> Map.add token_name ta tam
  | Some prev -> let new_amt: nat = match op with
                                    | INCREASE -> ta.amount + prev.amount
                                    | DECREASE -> if ta.amount > prev.amount then
                                                    (failwith Errors.unable_to_reduce_token_amount_to_less_than_zero : nat)
                                                  else
                                                    abs (prev.amount - ta.amount)
                 in
                 let new_tamt = { ta with amount = new_amt } in
                 Map.update token_name (Some new_tamt) tam

  let increase
  (ta: Types.token_amount)
  (tam : t): t =
  amend ta INCREASE tam

  let decrease
  (ta: Types.token_amount)
  (tam: t) : t =
  amend ta DECREASE tam

end

module Utils = struct

  type order = Types.swap_order
  type batch_set = Types.batch_set
  type batch = Types.batch

  let empty_prorata_equivalence : Types.prorata_equivalence = {
    buy_side_actual_volume = 0n;
    buy_side_actual_volume_equivalence = 0n;
    sell_side_actual_volume = 0n;
    sell_side_actual_volume_equivalence = 0n;
  }


  let nat_to_side
  (order_side : nat) : Types.side =
    if order_side = 0n then BUY
    else
      if order_side = 1n then SELL
      else failwith Errors.unable_to_parse_side_from_external_order

  let nat_to_tolerance (tolerance : nat) : Types.tolerance =
    if tolerance = 0n then MINUS
    else if tolerance = 1n then EXACT
    else if tolerance = 2n then PLUS
    else failwith Errors.unable_to_parse_tolerance_from_external_order

  let side_to_nat (side : Types.side) : nat = match side with
    | BUY -> 9n
    | SELL -> 1n

  let tolerance_to_nat (tolerance : Types.tolerance) : nat = match tolerance with
    | MINUS -> 0n
    | EXACT -> 1n
    | PLUS -> 2n

  let get_rate_name_from_swap (s : Types.swap) : string =
    let base_name = s.from.token.name in
    let quote_name = s.to.name in
    base_name ^ "/" ^ quote_name

  let get_rate_name_from_pair (s : Types.token * Types.token) : string =
    let (base, quote) = s in
    let base_name = base.name in
    let quote_name = quote.name in
    base_name ^ "/" ^ quote_name

  let get_inverse_rate_name_from_pair (s : Types.token * Types.token) : string =
    let (base, quote) = s in
    let quote_name = quote.name in
    let base_name = base.name in
    quote_name ^ "/" ^ base_name

  let get_rate_name (r : Types.exchange_rate) : string =
    let base_name = r.swap.from.token.name in
    let quote_name = r.swap.to.name in
    base_name ^ "/" ^ quote_name

  let pair_of_swap
    (side: Types.side)
    (swap: Types.swap): (Types.token * Types.token) =
    match side with
    | BUY -> (swap.from.token, swap.to)
    | SELL -> (swap.to, swap.from.token)

  let pair_of_rate (r : Types.exchange_rate) : (Types.token * Types.token) = pair_of_swap BUY r.swap

  let pair_of_external_swap (order : Types.external_swap_order) : (Types.token * Types.token) =
    (* Note:  we assume left-handedness - i.e. direction is buy side*)
    let swap = order.swap in
    let side = nat_to_side order.side in
    pair_of_swap side swap

  let pair_of_swap (order : Types.swap_order) : (Types.token * Types.token) =
    (* Note:  we assume left-handedness - i.e. direction is buy side*)
    let swap = order.swap in
    pair_of_swap order.side swap

  let get_token_name_from_token_amount
    (ta : Types.token_amount) : string =
    ta.token.name

  let get_token_name_from_token_holding
    (th : Types.token_holding) : string =
    th.token_amount.token.name

  let assign_new_holder_to_token_holding
    (new_holder : address)
    (token_holding : Types.token_holding) : Types.token_holding =
    { token_holding with holder = new_holder}

  let check_token_equality
    (this : Types.token_amount)
    (that : Types.token_amount) : Types.token_amount =
    if this.token.name = that.token.name then
      if this.token.address = that.token.address then
        that
      else
        (failwith Errors.tokens_do_not_match : Types.token_amount )
    else
      (failwith Errors.tokens_do_not_match : Types.token_amount )


  (* Converts a token_amount to a token holding by assigning a holder address *)
  let token_amount_to_token_holding
    (holder : address)
    (token_amount : Types.token_amount)
    (redeemed : bool): Types.token_holding =
    {
      holder =  holder;
      token_amount = token_amount;
      redeemed = redeemed;
    }



end

