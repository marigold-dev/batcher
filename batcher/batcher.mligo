#import "constants.mligo" "Constants"
#import "types.mligo" "Types"
#import "treasury.mligo" "Treasury"
#import "storage.mligo" "Storage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "clearing.mligo" "Clearing"
#import "batch.mligo" "Batch"
#import "orderbook.mligo" "Orderbook"
#import "userorderbook.mligo" "Userorderbook"
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
type batch_set = Types.Types.batch_set
type user_orders = Types.Types.user_orders

let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of external_order
  | Post of exchange_rate
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
  let clearing = Clearing.compute_clearing_prices inverse_rate batch in
  let batch = Batch.finalize batch current_time clearing rate in
  (inverse_rate, batch)

let progress_batch_set
   (batch_set: batch_set)
   (storage: storage): (bool *  batch_set) =
   let batches = batch_set.batches in
   match Batch.get_current_batch batch_set with
   | None -> (false, batch_set)
   | Some current_batch -> let current_time = Tezos.get_now () in
                           let (roll, updated_batch) =
                             if Batch.should_be_closed current_batch current_time then
                               let updated_batches = Batch.close current_batch in
                               (false,updated_batches)
                             else if Batch.should_be_cleared current_batch current_time then
                               let (_inverse_rate, finalized_batch) = finalize current_batch storage current_time in
                               (true, finalized_batch)
                             else
                               (false,current_batch)
                           in
                           let updated_batches = Big_map.update current_batch.batch_number (Some(updated_batch)) batches in
                           (roll, {batch_set with batches = updated_batches} )

let tick_current_batches (storage : storage) : storage =
  let batch_set = storage.batch_set in
  let (should_roll, updated_batch_set) = progress_batch_set batch_set storage in
  let rolled_if_needed = if should_roll then Batch.roll_batch_off updated_batch_set else updated_batch_set in
  { storage with batch_set = rolled_if_needed }

let try_to_append_order (order : order)
  (batch_set : Batch.batch_set) : Batch.batch_set =
  let current_batch_number = batch_set.current_batch_number in
  let current_batch = Batch.get_current_batch batch_set in
  match current_batch with
    | None ->
      failwith Errors.append_an_order_with_no_current_batch
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
          let updated_batches = Big_map.update current_batch_number (Some current) batch_set.batches in
          { batch_set with batches = updated_batches }

let external_to_order
  (order: external_order)
  (last_order_number: nat)
  (batch_number: nat) : order =
  let side = Types.Utils.nat_to_side(order.side) in
  let tolerance = Types.Utils.nat_to_tolerance(order.tolerance) in
  let converted_swap : order =
    {
      order_number = last_order_number + 1n;
      batch_number = batch_number;
      trader = order.trader;
      swap  = order.swap;
      created_at = order.created_at;
      side = side;
      tolerance = tolerance;
      redeemed = false;
    } in
  converted_swap

let order_to_external (order: order) : external_order =
  let side = Types.Utils.side_to_nat(order.side) in
  let tolerance = Types.Utils.tolerance_to_nat(order.tolerance) in
  let converted_swap : external_order =
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
let deposit (external_order: external_order) (storage : storage) : result =
  let current_batch = Batch.get_current_batch storage.batch_set in
  let (last_order_number, batch_number) = match current_batch with
                                             | None -> (0n, storage.batch_set.last_batch_number + 1n)
                                             | Some cb -> (cb.last_order_number, storage.batch_set.current_batch_number) in
  let order : order = external_to_order external_order last_order_number batch_number  in
  let ticked_storage = tick_current_batches storage in
  let current_time = Tezos.get_now () in
  let updated_batch_set =
    if Batch.should_open_new ticked_storage.batch_set current_time then
      Batch.start_period order ticked_storage.batch_set current_time
    else
      try_to_append_order order ticked_storage.batch_set
  in
  let updated_user_orderbook = Userorderbook.push_open_order external_order.trader order storage.user_orderbook in
  let updated_storage = { ticked_storage with batch_set = updated_batch_set; user_orderbook = updated_user_orderbook } in
  let (tokens_transfer_op, storage_after_treasury_update) = Treasury.deposit order.trader order.swap.from updated_storage in
  ([ tokens_transfer_op ], storage_after_treasury_update)

let redeem (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)


let move_current_to_previous_if_finalized (storage : storage) : storage =
  let batch_set = storage.batch_set in
  let current = Batch.get_current_batch batch_set in
  match current with
  | None -> storage
  | Some current_batch ->
     if (Batch.is_cleared current_batch) then
       let current_batch_number = batch_set.current_batch_number in
       let new_batch_set = { batch_set with current_batch_number = 0n; last_batch_number = current_batch_number; } in
       { storage with batch_set = new_batch_set }
     else
       storage


(* Post the rate in the contract and check if the current batch of orders needs to be cleared.
   TODO: actually update the rate *)
let post_rate (rate : exchange_rate) (storage : storage) : result =
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

let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Redeem -> redeem storage
