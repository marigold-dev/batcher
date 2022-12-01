#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "orderbook.mligo" "Orderbook"
#import "errors.mligo" "Errors"

module Types = CommonTypes.Types

type batch_set = Types.batch_set
type order = Types.swap_order

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : Types.clearing; rate : Types.exchange_rate }

(* Batch of orders for the same pair of tokens *)
type t = Types.batch

let roll_batch_off
  (batch_set : batch_set) : batch_set =
  if  batch_set.current_batch_number = 0n then
    batch_set
  else
    let batch_to_be_rolled = batch_set.current_batch_number in
    { batch_set with current_batch_number = 0n; last_batch_number = batch_to_be_rolled }

let make
  (order: order)
  (batch_number: nat)
  (timestamp: timestamp)
  (orderbook: Orderbook.t)
  (pair: Types.token * Types.token) : t =
  {
    batch_number= batch_number;
    status = Open { start_time = timestamp } ;
    orderbook = orderbook;
    last_order_number = order.order_number;
    pair = pair;
  }


(* Append an order to a batch *withouth checks* *)
let append_order (order : Types.swap_order) (batch : t) : t =
  let new_orderbook = Orderbook.push_order order batch.orderbook in
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
    | _ -> failwith Errors.batch_should_be_cleared

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

let should_be_cleared
  (batch : t)
  (current_time : timestamp) : bool =
  match batch.status with
    | Closed { start_time = _; closing_time } ->
      current_time > closing_time + Constants.price_wait_window
    | _ -> false

let get_current_batch
  (batch_set: batch_set) : t option =
  let cbn = batch_set.current_batch_number in
  if cbn = 0n then
    None
  else
    let bts = batch_set.batches in
    let cbf: t option = Big_map.find_opt cbn bts in
    cbf

let should_open_new
  (batch_set : batch_set)
  (_current_time : timestamp) : bool =
  let cb = get_current_batch batch_set in
  match cb with
  | None -> true
  | Some batch ->
      is_cleared batch



let start_period
  (order : Types.swap_order)
  (batch_set : batch_set)
  (current_time : timestamp) : batch_set =
    let pair = CommonTypes.Utils.pair_of_swap order in
    let orderbook = Orderbook.push_order order (Orderbook.empty ()) in
    let new_batch_number = batch_set.last_batch_number + 1n in
    let new_batch = make order new_batch_number current_time orderbook pair in
    let batches = Big_map.add new_batch_number new_batch batch_set.batches in
    { batch_set with batches = batches; current_batch_number = new_batch_number }

let close (batch : t) : t =
  match batch.status with
    | Open { start_time } ->
      let batch_close_time = start_time + Constants.deposit_time_window in
      let new_status = Closed { start_time = start_time; closing_time = batch_close_time } in
      { batch with status = new_status }
    | _ -> failwith Errors.trying_to_close_batch_which_is_not_open

let finalize (batch : t) (current_time : timestamp)
  (clearing : Types.clearing) (rate : Types.exchange_rate) : t =
  match batch.status with
    | Closed _ ->
      finalize batch current_time clearing rate
    | _ -> failwith Errors.trying_to_finalize_batch_which_is_not_closed

let new_batch_set : batch_set =
  {
    current_batch_number = 0n;
    last_batch_number= 0n;
    batches= (Big_map.empty: (nat, t) big_map);
  }
