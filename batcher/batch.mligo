#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "orderbook.mligo" "Order"

module Types = CommonTypes.Types

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : Types.clearing; rate : Types.exchange_rate }

(* Batch of orders for the same pair of tokens *)
type t = {
  status : batch_status;
  treasury : Types.treasury;
  orderbook : Order.t;
  pair : Types.token * Types.token;
}

(* Set of batches, containing the current batch and the previous (finalized) batches.
   The current batch can be open for deposits, closed for deposits (awaiting clearing) or
   finalized, as we wait for a new deposit to start a new batch *)
type batch_set = {
  current : t option;
  previous : t list;
}

let make (timestamp : timestamp) (orderbook : Order.t)
  (pair : Types.token * Types.token) (treasury : Types.treasury) : t =
  {
    status = Open { start_time = timestamp } ;
    orderbook = orderbook;
    treasury = treasury;
    pair = pair;
  }

(* Append an order to a batch *withouth checks* *)
let append_order (order : Types.swap_order) (batch : t) : t =
  let new_orderbook = Order.push_order order batch.orderbook in
  { batch with orderbook = new_orderbook }

let finalize (batch : t) (current_time : timestamp) (clearing : Types.clearing)
  (rate : Types.exchange_rate) : t =
  {
    batch with status = Cleared {
      at = current_time;
      clearing = clearing;
      rate = rate
    }
  }

let get_status_when_its_cleared (batch : t) =
  match batch.status with
    | Cleared infos -> infos
    | _ -> failwith "this batch must be cleared before using this function"

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

let should_open_new (batches : batch_set) (_current_time : timestamp) : bool =
  match batches.current with
    | None -> true
    | Some batch ->
      is_cleared batch

let start_period (order : Types.swap_order) (batches : batch_set)
  (current_time : timestamp) (treasury : Types.treasury) : batch_set =
    let pair = CommonTypes.Utils.pair_of_swap order.swap in
    let orderbook = Order.push_order order (Order.empty ()) in
    let new_batch = make current_time orderbook pair treasury in
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
  (clearing : Types.clearing) (rate : Types.exchange_rate) : t =
  match batch.status with
    | Closed _ ->
      finalize batch current_time clearing rate
    | _ -> failwith "Trying to finalize a batch which is not closed"

let new_batch_set : batch_set =
  { current = None; previous = [] }
