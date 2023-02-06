#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "orderbook.mligo" "Orderbook"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/rational.mligo" "Rational"

module Types = CommonTypes.Types
module Utils = CommonTypes.Utils

type batch_set = Types.batch_set
type order = Types.swap_order
type pair = Types.pair
type rate = Types.exchange_rate
type clearing = Types.clearing

(* Batch of orders for the same pair of tokens *)
type t = Types.batch

module BatchPriv = struct

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : Types.clearing; rate : Types.exchange_rate }


let set_buy_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | Minus -> { volumes with buy_minus_volume = volumes.buy_minus_volume + order.swap.from.amount; }
  | Exact -> { volumes with buy_exact_volume = volumes.buy_exact_volume + order.swap.from.amount; }
  | Plus -> { volumes with buy_plus_volume = volumes.buy_plus_volume + order.swap.from.amount; }

let set_sell_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | Minus -> { volumes with sell_minus_volume = volumes.sell_minus_volume + order.swap.from.amount; }
  | Exact -> { volumes with sell_exact_volume = volumes.sell_exact_volume + order.swap.from.amount; }
  | Plus -> { volumes with sell_plus_volume = volumes.sell_plus_volume + order.swap.from.amount; }


let make
  (batch_number: nat)
  (timestamp: timestamp)
  (pair: Types.token * Types.token) : t =
  let volumes: Types.volumes = {
      buy_minus_volume = 0n;
      buy_exact_volume = 0n;
      buy_plus_volume = 0n;
      sell_minus_volume = 0n;
      sell_exact_volume = 0n;
      sell_plus_volume = 0n;
    } in
  {
    batch_number= batch_number;
    status = Open { start_time = timestamp } ;
    pair = pair;
    volumes = volumes;
  }

let update_current_batch_in_set
  (batch : t)
  (batch_set : batch_set) : (t * batch_set)=
  let updated_batches = Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let name = Utils.get_rate_name_from_pair batch.pair in
  let updated_batch_indices = Map.update name (Some batch.batch_number) batch_set.current_batch_indices in
  ( batch, { batch_set with batches = updated_batches; current_batch_indices = updated_batch_indices; } )



let get_status_when_its_cleared (batch : t) =
  match batch.status with
    | Cleared infos -> infos
    | _ -> failwith Errors.batch_should_be_cleared

let should_be_cleared
  (batch : t)
  (current_time : timestamp) : bool =
  match batch.status with
    | Closed { start_time = _; closing_time } ->
      current_time > closing_time + Constants.price_wait_window
    | _ -> false

let start_period
  (pair : pair)
  (batch_set : batch_set)
  (current_time : timestamp) : (t * batch_set) =
  let highest_batch_index = Utils.get_highest_batch_index batch_set.current_batch_indices in
  let new_batch_number = highest_batch_index + 1n in
  let new_batch = make new_batch_number current_time pair in
  update_current_batch_in_set new_batch batch_set

let close (batch : t) : t =
  match batch.status with
    | Open { start_time } ->
      let batch_close_time = start_time + Constants.deposit_time_window in
      let new_status = Closed { start_time = start_time; closing_time = batch_close_time } in
      { batch with status = new_status }
    | _ -> failwith Errors.trying_to_close_batch_which_is_not_open


let new_batch_set : batch_set =
  {
    current_batch_indices = (Map.empty: (string, nat) map);
    batches= (Big_map.empty: (nat, t) big_map);
  }

let progress_batch
  (pair: pair)
  (batch: t)
  (batch_set: batch_set)
  (current_time : timestamp) : (t * batch_set) =
  match batch.status with
  | Open { start_time } ->
    if  current_time > start_time + Constants.price_wait_window then
      let closed_batch = close batch in
      update_current_batch_in_set closed_batch batch_set
    else
      (batch, batch_set)
  | Closed { closing_time =_ ; start_time = _} ->
    (*  Batches can only be cleared on receipt of rate so here they should just be returned *)
    (batch, batch_set)
  | Cleared _ -> start_period pair batch_set current_time

end

let update_volumes
  (order: Types.swap_order)
  (batch : t)  : t =
  let vols = batch.volumes in
  let updated_vols = match order.side with
                     | Buy -> BatchPriv.set_buy_side_volume order vols
                     | Sell -> BatchPriv.set_sell_side_volume order vols
  in
  { batch with volumes = updated_vols;  }

let can_deposit
  (batch:t) : bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


let can_be_finalized
  (batch : t)
  (current_time : timestamp) : bool = BatchPriv.should_be_cleared batch current_time


let finalize_batch
  (batch : t)
  (clearing: clearing)
  (current_time : timestamp)
  (rate : Types.exchange_rate)
  (batch_set : batch_set): batch_set =
  let finalized_batch : t = {
      batch with status = Cleared {
        at = current_time;
        clearing = clearing;
        rate = rate
      }
    } in
  let (_, ucb) = BatchPriv.update_current_batch_in_set finalized_batch batch_set in
  ucb

let get_current_batch
  (pair: pair)
  (current_time: timestamp)
  (batch_set: batch_set) : (t * batch_set) =
  let current_batch_index = Utils.get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  BatchPriv.start_period pair batch_set current_time
  | Some cb ->  BatchPriv.progress_batch pair cb batch_set current_time
