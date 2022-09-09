#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/float.mligo" "Float"


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

  (* A token amount 'held' by a specific address *)
  type token_holding = {
    [@layout:comb]
    holder: address;
    token_amount : token_amount;
  }

  type swap = {
   from : token_amount;
   to : token;
  }

  (*I change the type of the rate from tez to nat for sake of simplicity*)
  type exchange_rate = {
    [@layout:comb]
    swap : swap;
    rate: Float.t;
    when : timestamp;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    created_at : timestamp;
    side : side;
    tolerance : tolerance;
  }

  type batch_status  = NOT_OPEN | OPEN | CLOSED | FINALIZED

  type clearing = {
    clearing_volumes : (tolerance, nat) map;
    clearing_tolerance : tolerance;
  }

  type treasury_item_status = DEPOSITED | EXCHANGED | CLAIMED

  type treasury_holding = (string, token_holding) map

  type treasury = (address, treasury_holding) big_map

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
    Here, the orderbook is a list of bids orders and asks orders
  *)
  type orderbook = {
    bids : swap_order list;
    asks : swap_order list
  }

  type batch_status =
    | Open of { start_time : timestamp }
    | Closed of { start_time : timestamp ; closing_time : timestamp }
    | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }

  (* Batch of orders for the same pair of tokens *)
  type batch = {
    status : batch_status;
    treasury : treasury;
    orderbook : orderbook;
    pair : token * token;
  }

  (* Set of batches, containing the current batch and the previous (finalized) batches.
     The current batch can be open for deposits, closed for deposits (awaiting clearing) or
     finalized, as we wait for a new deposit to start a new batch *)
  type batch_set = {
    current : batch option;
    previous : batch list;
  }
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
    (token_amount : Types.token_amount) : Types.token_holding =
    {
      holder =  holder;
      token_amount = token_amount;
    }




end

