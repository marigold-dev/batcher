#import "constants.mligo" "Constants"
#import "types.mligo" "Types"
#import "treasury.mligo" "Treasury"
#import "storage.mligo" "Storage"
#import "prices.mligo" "Pricing"
#import "math.mligo" "Math"
#import "clearing.mligo" "Clearing"
#import "userbatchordertypes.mligo" "Ubot"
#import "batch.mligo" "Batch"
#import "orderbook.mligo" "Orderbook"
#import "errors.mligo" "Errors"
#import "../math_lib/lib/rational.mligo" "Rational"

type storage  = Storage.Types.t
type result = (operation list) * storage
type order = Types.Types.swap_order
type swap = Types.Types.swap
type valid_swaps = Storage.Types.valid_swaps
type external_order = Types.Types.external_swap_order
type side = Types.Types.side
type tolerance = Types.Types.tolerance
type exchange_rate = Types.Types.exchange_rate
type inverse_exchange_rate = exchange_rate
type batch_set = Types.Types.batch_set
type pair = Types.Types.pair

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
        rate = Rational.inverse r.rate;
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
   (pair : pair)
   (batch_sets: batch_set)
   (storage: storage): (bool *  batch_set) =
   let (cb_opt, bs) = Batch.get_current_batch pair batch_sets in
   match cb_opt with
   | None -> (false, bs)
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
                           let updated_batches = Big_map.update current_batch.batch_number (Some(updated_batch)) bs.batches in
                           (roll, {bs with batches = updated_batches} )

let tick_current_batches
  (pair: pair)
  (storage : storage) : storage =
  let batch_set = storage.batch_set in
  let (should_roll, updated_batch_set) = progress_batch_set pair batch_set storage in
  let rolled_if_needed = if should_roll then Batch.roll_batch_off updated_batch_set else updated_batch_set in
  { storage with batch_set = rolled_if_needed }

let is_valid_swap_pair
  (order: order)
  (valid_swaps: valid_swaps): order =
  let token_pair = Types.Utils.pair_of_swap order in
  let rate_name = Types.Utils.get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then order else failwith Errors.unsupported_swap_type

let external_to_order
  (order: external_order)
  (order_number: nat)
  (batch_number: nat)
  (valid_swaps: valid_swaps): order =
  let side = Types.Utils.nat_to_side(order.side) in
  let tolerance = Types.Utils.nat_to_tolerance(order.tolerance) in
  let sender = Tezos.get_sender () in
  let converted_swap : order =
    {
      order_number = order_number;
      batch_number = batch_number;
      trader = sender;
      swap  = order.swap;
      created_at = order.created_at;
      side = side;
      tolerance = tolerance;
      redeemed = false;
    } in
  is_valid_swap_pair converted_swap valid_swaps

let order_to_external (order: order) : external_order =
  let side = Types.Utils.side_to_nat(order.side) in
  let tolerance = Types.Utils.tolerance_to_nat(order.tolerance) in
  let converted_swap : external_order =
    {
      swap  = order.swap;
      created_at = order.created_at;
      side = side;
      tolerance = tolerance;
    } in
  converted_swap

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (external_order: external_order) (old_storage : storage) : result =
  let pair = Types.Utils.pair_of_external_swap external_order in
  let ticked_storage = tick_current_batches pair old_storage in
  let (current_batch_opt, current_batch_set) = Batch.get_current_batch pair ticked_storage.batch_set in
  match current_batch_opt with
  | None -> failwith Errors.no_open_batch
  | Some current_batch-> let current_batch_number = current_batch.batch_number in
                         let next_order_number = ticked_storage.last_order_number + 1n in
                         let order : order = external_to_order external_order next_order_number current_batch_number ticked_storage.valid_swaps in
                         (* We intentionally limit the amount of distinct orders that can be placed whilst unredeemed orders exist for a given user  *)
                         if Ubot.is_within_limit order.trader old_storage.user_batch_ordertypes then
                           let new_orderbook = Big_map.add next_order_number order ticked_storage.orderbook in
                           let new_ubot = Ubot.add_order order.trader current_batch_number order old_storage.user_batch_ordertypes in
                           let updated_volumes = Batch.update_volumes order current_batch in
                           let updated_batches = Big_map.update current_batch_number (Some updated_volumes) current_batch_set.batches in
                           let updated_batch_set = { current_batch_set with batches = updated_batches } in
                           let updated_storage = {
                             ticked_storage with batch_set = updated_batch_set;
                             orderbook = new_orderbook;
                             last_order_number = next_order_number;
                             user_batch_ordertypes = new_ubot; } in
                           let tokens_transfer_op = Treasury.deposit order.trader order.swap.from in
                           ([ tokens_transfer_op ], updated_storage)
                          else
                            failwith Errors.too_many_unredeemed_orders

let redeem
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)


let move_current_to_previous_if_finalized
  (pair: pair)
  (storage : storage) : storage =
  let batch_set = storage.batch_set in
  let (current_batch_op, current_batch_set) = Batch.get_current_batch pair batch_set in
  match current_batch_op with
  | None -> storage
  | Some current_batch ->
     if (Batch.is_cleared current_batch) then
       let current_batch_number = batch_set.current_batch_number in
       let new_batch_set = { current_batch_set with current_batch_number = 0n; last_batch_number = current_batch_number; } in
       { storage with batch_set = new_batch_set }
     else
       storage


(* Post the rate in the contract and check if the current batch of orders needs to be cleared.
   TODO: actually update the rate *)
let post_rate (rate : exchange_rate) (storage : storage) : result =
  let updated_rate_storage = Pricing.Rates.post_rate rate storage in
  let pair = Types.Utils.pair_of_rate rate in
  let ticked_storage = tick_current_batches pair updated_rate_storage in
  let moved_storage = move_current_to_previous_if_finalized pair ticked_storage in
  no_op (moved_storage)


let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Redeem -> redeem storage

