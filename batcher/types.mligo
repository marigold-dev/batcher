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

  (*This type represent a result of a match computation, we can partially or totally match two orders*)
  type match_result = Total | Partial of swap_order

  type clearing = {
    clearing_volumes : (tolerance, nat)  map;
    clearing_tolerance : tolerance;
  }

  type batch_status =
    | Open of { start_time : timestamp }
    | Closed of { start_time : timestamp ; closing_time : timestamp }
    | Cleared of { at : timestamp; clearing : clearing }

  type treasury_item_status = DEPOSITED | EXCHANGED | CLAIMED

  type treasury_item = {
   token_amount : token_amount;
   status : batch_status;
  }

  type treasury = (address, treasury_item) big_map

  type order_distribution = ((side * tolerance), nat) map

  module Batch = struct

    type t = {
      status : batch_status;
      orders: swap_order list;
    }

    (* Set of batches, containing the current batch and the previous (finalized) batches.
       The current batch can be open for deposits, closed for deposits (awaiting clearing) or
       finalized, as we wait for a new deposit to start a new batch *)
    type batch_set = {
      current : t option;
      previous : t list;
    }

    let make (timestamp : timestamp) (orders : swap_order list) : t =
      {
        status = Open { start_time = timestamp } ;
        orders = orders;
      }

    (* Append an order to a batch *withouth checks* *)
    let append_order (order : swap_order) (batch : t) : t =
      { batch with orders = order :: batch.orders }

    let finalize (batch : t) (current_time : timestamp) (clearing : clearing) : t =
      {
        batch with status = Cleared {
          at = current_time;
          clearing = clearing
        }
      }

    let is_open (batch : t) : bool =
      match batch.status with
        | Open _ -> true
        | _ -> false

    let is_closed (batch : t) : bool =
      match batch.status with
        | Closed _ -> true
        | _ -> false

    let is_cleared (batch : t) : bool =
      match batch.status with
        | Cleared _ -> true
        | _ -> false

    let should_be_closed (batch : t) (current_time : timestamp) : bool =
      match batch.status with
        | Open { start_time } ->
          current_time > start_time + Constants.deposit_time_window
        | _ -> false

    let should_be_cleared (batch : t) (current_time : timestamp) : bool =
      match batch.status with
        | Closed { start_time = _; closing_time } ->
          current_time > closing_time + Constants.price_wait_window
        | _ -> false

    let should_open_new (batches : batch_set) (current_time : timestamp) : bool =
      match batches.current with
        | None -> true
        | Some batch ->
          is_cleared batch

    let start_period (order : swap_order) (batches : batch_set)
      (current_time : timestamp) : batch_set =
        let new_batch = make current_time [order] in
        match batches.current with
          | None ->
            { batches with current = Some new_batch }
          | Some old_batch ->
            { batches with current = Some new_batch ; previous = old_batch :: batches.previous }

    let close (batch : t) (current_time : timestamp) : t =
      match batch.status with
        | Open { start_time } ->
          { batch with status = Closed { start_time = start_time;
            closing_time = current_time } }
        | _ -> failwith "Trying to close a batch which is not open"

    let finalize (batch : t) (current_time : timestamp)
      (clearing : clearing) : t =
      match batch.status with
        | Closed _ ->
          { batch with status = Cleared { at = current_time;
            clearing = clearing } }
        | _ -> failwith "Trying to finalize a batch which is not closed"

    let new_batch_set : batch_set =
      { current = None; previous = [] }
  end
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

