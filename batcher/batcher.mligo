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

type storage  = Storage.Types.t
type result = (operation list) * storage
type order = Types.Types.swap_order

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of Types.Types.swap_order
  | Post of Types.Types.exchange_rate
  | Tick
  | Redeem


let finalize (batch : Batch.t) (storage : storage) (current_time : timestamp) : Batch.t =
  let rate_name = Types.Utils.get_rate_name_from_pair batch.pair in
  let rate =
    match Big_map.find_opt rate_name storage.rates_current with
        | None -> (failwith Pricing.PriceErrors.no_rate_available_for_swap : Types.Types.exchange_rate)
        | Some r -> r
  in
  let clearing = Clearing.compute_clearing_prices rate storage in
  Batch.finalize batch current_time clearing rate

let tick_current_batches (storage : storage) : storage =
  let batches = storage.batches in
  let updated_batches =
    match batches.current with
      | None ->
        batches
      | Some batch ->
        let current_time = Tezos.get_now () in
        let batch =
          if Batch.should_be_closed batch current_time then
            Batch.close batch current_time
          else if Batch.should_be_cleared batch current_time then
            (* Finalize the current batch, but does not open a new one before we receive
               a new deposit *)
            finalize batch storage current_time
          else
            batch
        in
        { batches with current = Some batch }
  in
  { storage with batches = updated_batches }

let try_to_append_order (order : Types.Types.swap_order)
  (batches : Batch.batch_set) : Batch.batch_set =
  match batches.current with
    | None ->
      failwith "Append an order with no current batch" (* FIXME: make this impossible *)
    | Some current ->
      if not (Batch.is_open current) then
        failwith "Append an order to a non open batch"
      else
        let current_pair = current.pair in
        let order_pair = Types.Utils.pair_of_swap order.swap in
        if current_pair <> order_pair then
          failwith Errors.order_pair_doesnt_match
        else
          let current = Batch.append_order order current in
          { batches with current = Some current }

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (order: Types.Types.swap_order) (storage : storage) : result =
  let storage = tick_current_batches storage in
  let current_time = Tezos.get_now () in
  let updated_batches =
    if Batch.should_open_new storage.batches current_time then
      Batch.start_period order storage.batches current_time
    else
      try_to_append_order order storage.batches
  in
  let storage = { storage with batches = updated_batches } in
  (* FIXME We should take the deposit before updating the batch ideally.  That way we can be sure we actually have the token we are trying to swap *)
  let storage_after_treasury_update = Treasury.deposit order.trader order.swap.from storage in
  no_op (storage_after_treasury_update)

let redeem (storage : storage) : result =
  let holder = Tezos.get_sender () in
  no_op(Treasury.redeem holder storage)


(* Post the rate in the contract and check if the current batch of orders needs to be cleared.
   TODO: actually update the rate *)
let post_rate (rate : Types.Types.exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  match storage.batches.current with
    (* TODO: find a way to remove these tests? *)
    | None -> no_op (storage)
    | Some current_batch ->
      let updated_batches =
        let current_time = Tezos.get_now () in
        if Batch.should_be_cleared current_batch current_time then
          let batch = finalize current_batch storage current_time in
          let cleared_infos = Batch.get_status_when_its_cleared batch in
          let updated_treasury, new_orderbook =
            Orderbook.orders_execution batch.orderbook cleared_infos.clearing cleared_infos.rate batch.treasury in
          let new_batch = {batch with orderbook = new_orderbook; treasury = updated_treasury} in
          { storage.batches with current = Some new_batch }
        else
          storage.batches
      in
        no_op ({ updated_rate_storage with batches = updated_batches } )

let tick (storage : storage) : result =
  let updated_storage = tick_current_batches storage in
  no_op (updated_storage)

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
let get_current_exchange_rate (rate_name, storage : string * storage) : Types.Types.exchange_rate = 
  match Big_map.get_and_update 
    rate_name
    (None : Types.Types.exchange_rate option) 
    storage.rates_current 
  with 
  | (None, _rates_current) -> failwith Errors.not_found_rate_name
  | (Some current_rate, _rates_current) -> current_rate

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Tick -> tick storage
   | Redeem -> redeem storage

