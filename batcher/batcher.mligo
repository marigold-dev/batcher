#import "constants.mligo" "Constants"
#import "types.mligo" "Types"
#import "treasury.mligo" "Treasury"
#import "storage.mligo" "Storage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "clearing.mligo" "Clearing"
#import "batch.mligo" "Batch"
#import "orderbook.mligo" "Orderbook"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/float.mligo" "Float"

type storage  = Storage.Types.t
type result = (operation list) * storage
type order = Types.Types.swap_order
type external_order = Types.Types.external_swap_order
type side = Types.Types.side
type tolerance = Types.Types.tolerance
type exchange_rate = Types.Types.exchange_rate
type inverse_exchange_rate = exchange_rate

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of Types.Types.external_swap_order
  | Post of Types.Types.exchange_rate
  | Redeem

let get_inverse_exchange_rate (rate_name : string) (current_rate : Storage.Types.rates_current) : inverse_exchange_rate * exchange_rate = 
  match Big_map.find_opt rate_name current_rate with 
  | None -> failwith Pricing.PriceErrors.no_rate_available_for_swap
  | Some r ->  
      let base_token = r.swap.from.token in 
      let quote_token = r.swap.to in
      let new_base_token = { r.swap.from with token = quote_token } in 
      let new_quote_token = base_token in  
      let inverse_rate : inverse_exchange_rate = {
        swap = { from = new_base_token; to = new_quote_token };
        rate = Float.inverse r.rate;
        when = r.when;
      } in 
      (inverse_rate, r)

let finalize (batch : Batch.t) (storage : storage) (current_time : timestamp) : (inverse_exchange_rate * Batch.t) =
  let (inverse_rate, rate) = 
    if Big_map.mem (Types.Utils.get_rate_name_from_pair batch.pair) storage.rates_current then 
      match Big_map.find_opt (Types.Utils.get_rate_name_from_pair batch.pair) storage.rates_current with
      | None -> failwith Pricing.PriceErrors.no_rate_available_for_swap
      | Some r -> (r, r) 
    else if Big_map.mem (Types.Utils.get_inverse_rate_name_from_pair batch.pair) storage.rates_current then 
      get_inverse_exchange_rate (Types.Utils.get_inverse_rate_name_from_pair batch.pair) storage.rates_current
    else 
      failwith Pricing.PriceErrors.no_rate_available_for_swap
  in
  let clearing = Clearing.compute_clearing_prices inverse_rate storage in
  let batch = Batch.finalize batch current_time clearing rate in 
  (inverse_rate, batch)

let tick_current_batches (storage : storage) : storage =
  let batches = storage.batches in
  let updated_batches =
    match batches.current with
      | None -> batches
      | Some current_batch ->
        let current_time = Tezos.get_now () in
        let updated_batch =
          if Batch.should_be_closed current_batch current_time then
            Batch.close current_batch
          else if Batch.should_be_cleared current_batch current_time then
            let (inverse_rate, finalized_batch) = finalize current_batch storage current_time in
            let cleared_infos = Batch.get_status_when_its_cleared finalized_batch in
            let updated_treasury, new_orderbook = Orderbook.orders_execution current_batch.orderbook cleared_infos.clearing inverse_rate finalized_batch.treasury in
            {finalized_batch with orderbook = new_orderbook; treasury = updated_treasury}
          else
            current_batch
        in
        { batches with current = Some updated_batch }
  in
  { storage with batches = updated_batches }

let try_to_append_order (order : Types.Types.swap_order)
  (batches : Batch.batch_set) : Batch.batch_set =
  match batches.current with
    | None ->
      failwith Errors.append_an_order_with_no_current_batch (* FIXME: make this impossible *)
    | Some current ->
      if not (Batch.is_open current) then
        failwith Errors.append_an_order_to_a_non_open_batch
      else
        let current_pair = current.pair in
        let order_pair = Types.Utils.pair_of_swap order in
        if current_pair <> order_pair then
          failwith Errors.order_pair_doesnt_match
        else
          let current = Batch.append_order order current in
          { batches with current = Some current }

let convert_order (order: external_order) : Types.Types.swap_order =
  let side = Types.Utils.parse_side(order.side) in
  let tolerance = Types.Utils.parse_tolerance(order.tolerance) in
  let converted_swap : Types.Types.swap_order =
    {
      trader = order.trader;
      swap  = order.swap;
      created_at = order.created_at;
      side = side;
      tolerance = tolerance;
    } in
  converted_swap

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (external_order: Types.Types.external_swap_order) (storage : storage) : result =
  let order = convert_order external_order in
  let ticked_storage = tick_current_batches storage in
  let current_time = Tezos.get_now () in
  let updated_batches =
    if Batch.should_open_new ticked_storage.batches current_time then
      Batch.start_period order ticked_storage.batches current_time
    else
      try_to_append_order order ticked_storage.batches
  in
  let updated_storage = { ticked_storage with batches = updated_batches } in
  (* FIXME We should take the deposit before updating the batch ideally.  That way we can be sure we actually have the token we are trying to swap *)
  let (_tokens_transfer_op, storage_after_treasury_update) = Treasury.deposit order.trader order.swap.from updated_storage in
  no_op storage_after_treasury_update

let redeem (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)


let move_current_to_previous_if_finalized (storage : storage) : storage = 
  let batches = storage.batches in
  let current = batches.current in
  match current with
  | None -> storage
  | Some current_batch -> 
     if (Batch.is_cleared current_batch) then
       let previous = batches.previous in
       let new_previous = current_batch :: previous in
       let new_current : Types.Types.batch option= None in 
       let new_batches = { batches with current = new_current; previous = new_previous } in
       { storage with batches = new_batches }
     else
       storage


(* Post the rate in the contract and check if the current batch of orders needs to be cleared.
   TODO: actually update the rate *)
let post_rate (rate : Types.Types.exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  let ticked_storage = tick_current_batches updated_rate_storage in
  let moved_storage = move_current_to_previous_if_finalized ticked_storage in
  no_op (moved_storage)

[@inline]
let filter_orders_by_user
  (user : address)
  (orders : order list)
  (new_orders : order list) : order list =
    let filter (new_orders, order : order list * order) : order list =
      if order.trader = user then
        order :: new_orders
      else
        new_orders
    in
    List.fold_left filter new_orders orders

[@view]
let get_deposit_starting_time ((), storage : unit * storage) : timestamp =
  match storage.batches.current with
  | None -> failwith Errors.not_open_batch
  | Some current_batch ->
    let start_time =
      match current_batch.status with
      | Open { start_time } -> start_time
      | _ -> failwith Errors.not_open_status in
    start_time

[@view]
let get_order_books ((), storage : unit * storage) : Orderbook.t =
  match storage.batches.current with
  | None -> failwith Errors.not_open_batch
  | Some current_batch -> current_batch.orderbook

[@view]
let get_current_orders_by_user (user, storage : address * storage) : order list =
  match storage.batches.current with
  | None -> failwith Errors.not_open_batch
  | Some current_batch ->
    let new_orders = filter_orders_by_user user current_batch.orderbook.bids ([] : order list) in
    let new_orders = filter_orders_by_user user current_batch.orderbook.asks new_orders in
    new_orders

[@view]
let get_previous_orders_by_user (user, storage : address * storage) : order list =
  match storage.batches.previous with
  | [] -> failwith Errors.not_previous_batches
  | _ ->
    let filter (new_orders, batch : order list * Batch.t) : order list =
      let new_orders = filter_orders_by_user user batch.orderbook.bids new_orders in
      let new_orders = filter_orders_by_user user batch.orderbook.asks new_orders in
      new_orders
    in
    List.fold_left filter ([] : order list) storage.batches.previous

[@view]
let get_current_exchange_pair ((), storage : unit * storage) : string =
  match storage.batches.current with
  | None -> failwith Errors.not_open_batch
  | Some current_batch -> 
    Types.Utils.get_rate_name_from_pair current_batch.pair


let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Redeem -> redeem storage

