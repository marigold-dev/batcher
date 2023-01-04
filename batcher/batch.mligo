#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "orderbook.mligo" "Orderbook"
#import "errors.mligo" "Errors"

module Types = CommonTypes.Types

type batch_set = Types.batch_set
type order = Types.swap_order
type pair = Types.pair

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

let set_buy_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | MINUS -> { volumes with buy_minus_volume = volumes.buy_minus_volume + order.swap.from.amount; }
  | EXACT -> { volumes with buy_exact_volume = volumes.buy_exact_volume + order.swap.from.amount; }
  | PLUS -> { volumes with buy_plus_volume = volumes.buy_plus_volume + order.swap.from.amount; }

let set_sell_side_volume
  (order: Types.swap_order)
  (volumes : Types.volumes) : Types.volumes =
  match order.tolerance with
  | MINUS -> { volumes with sell_minus_volume = volumes.sell_minus_volume + order.swap.from.amount; }
  | EXACT -> { volumes with sell_exact_volume = volumes.sell_exact_volume + order.swap.from.amount; }
  | PLUS -> { volumes with sell_plus_volume = volumes.sell_plus_volume + order.swap.from.amount; }

let update_volumes
  (order: Types.swap_order)
  (batch : t)  : t =
  let vols = batch.volumes in
  let updated_vols = match order.side with
                     | BUY -> set_buy_side_volume order vols
                     | SELL -> set_sell_side_volume order vols
  in
  { batch with volumes = updated_vols;  }

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


let should_open_new
  (current_batch_op : t option) : bool =
  match current_batch_op with
  | None -> true
  | Some batch ->
      is_cleared batch


let start_period
  (pair : pair)
  (batch_set : batch_set)
  (current_time : timestamp) : (t * batch_set) =
  let new_batch_number = batch_set.last_batch_number + 1n in
  let new_batch = make new_batch_number current_time pair in
  let batches = Big_map.add new_batch_number new_batch batch_set.batches in
  (new_batch, { batch_set with batches = batches; current_batch_number = new_batch_number })

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


[@inline]
let reset_batch_set
  (batch_set: batch_set) : (t option * batch_set) =
  let last_batch_number = batch_set.last_batch_number in
  let batches = batch_set.batches in
  match Big_map.find_opt last_batch_number batches with
  | None -> failwith Errors.unable_to_determine_current_or_previous_batch
  | Some b -> let updated_batch_set = { batch_set with current_batch_number = last_batch_number } in
              (Some b, updated_batch_set)


[@inline]
let get_current_batch
  (pair: pair)
  (batch_set: batch_set) : (t option * batch_set) =
  let current_time = Tezos.get_now () in
  let current_batch_number = batch_set.current_batch_number in
  if current_batch_number = 0n then
    let (b,bs) = start_period pair batch_set current_time in
    (Some b, bs)
  else
    let batches = batch_set.batches in
    match Big_map.find_opt current_batch_number batches with
    | None ->  (* This should never happen but if it does then we should set back to last batch number *)
               reset_batch_set batch_set
    | Some cb -> if should_open_new (Some cb) then
                   let (b,bs) = start_period pair batch_set current_time in
                   (Some b, bs)
                 else
                   (Some cb, batch_set)

