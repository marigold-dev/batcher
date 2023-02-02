#import "constants.mligo" "Constants"
#import "types.mligo" "Types"
#import "treasury.mligo" "Treasury"
#import "storage.mligo" "Storage"
#import "prices.mligo" "Pricing"
#import "clearing.mligo" "Clearing"
#import "math.mligo" "Math"
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
type valid_tokens = Storage.Types.valid_tokens
type external_order = Types.Types.external_swap_order
type side = Types.Types.side
type tolerance = Types.Types.tolerance
type rate = Types.Types.exchange_rate
type inverse_rate = rate
type batch_set = Types.Types.batch_set
type batch = Types.Types.batch
type clearing = Types.Types.clearing
type pair = Types.Types.pair
type token = Types.Types.token
let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of external_order
  | Post of rate
  | Redeem
  | Change_fee of tez
  | Change_admin_address of address


let is_administrator
  (storage : storage) : unit =
  assert_with_error
   (Tezos.get_sender () = storage.administrator)
   (failwith Errors.sender_not_administrator)


let are_equivalent_tokens
  (given: token)
  (test: token) : bool =
    given.name = test.name &&
    given.address = test.address &&
    given.decimals = test.decimals &&
    given.standard = test.standard

 let is_valid_swap_pair
  (side: side)
  (swap: swap)
  (valid_swaps: valid_swaps): swap =
  let token_pair = Types.Utils.pair_of_swap side swap in
  let rate_name = Types.Utils.get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith Errors.unsupported_swap_type

let validate
  (side: side)
  (swap: swap)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): swap =
  let from = swap.from.token in
  let to = swap.to in
  match Map.find_opt from.name valid_tokens with
  | None ->  failwith Errors.unsupported_swap_type
  | Some ft -> (match Map.find_opt to.name valid_tokens with
                | None -> failwith Errors.unsupported_swap_type
                | Some tt -> if (are_equivalent_tokens from ft) && (are_equivalent_tokens to tt) then
                              is_valid_swap_pair side swap valid_swaps
                            else
                              failwith Errors.unsupported_swap_type)

let invert_rate_for_clearing
  (rate : rate) : rate  =
  let base_token = rate.swap.from.token in
  let quote_token = rate.swap.to in
  let new_base_token = { rate.swap.from with token = quote_token } in
  let new_quote_token = base_token in
  let new_rate: rate = {
      swap = { from = new_base_token; to = new_quote_token };
      rate = Rational.inverse rate.rate;
      when = rate.when;
  } in
  new_rate

let finalize
  (batch : batch)
  (current_time : timestamp)
  (rate : rate)
  (batch_set : batch_set): batch_set =
  if Batch.can_be_finalized batch current_time then
    let current_time = Tezos.get_now () in
    let inverse_rate : rate = invert_rate_for_clearing rate in
    let clearing : clearing = Clearing.compute_clearing_prices inverse_rate batch in
    Batch.finalize_batch batch clearing current_time rate batch_set
  else
    batch_set

let external_to_order
  (order: external_order)
  (order_number: nat)
  (batch_number: nat)
  (valid_tokens: valid_tokens)
  (valid_swaps: valid_swaps): order =
  let side = Types.Utils.nat_to_side(order.side) in
  let tolerance = Types.Utils.nat_to_tolerance(order.tolerance) in
  let sender = Tezos.get_sender () in
  let converted_order : order =
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
  let validated_swap = validate side order.swap valid_tokens valid_swaps in
  { converted_order with swap = validated_swap; }

(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
let deposit (external_order: external_order) (storage : storage) : result =
  let pair = Types.Utils.pair_of_external_swap external_order in
  let current_time = Tezos.get_now () in

  let fee_amount_in_mutez = storage.fee_in_mutez in
  let fee_provided = Tezos.get_amount () in
  if fee_provided < fee_amount_in_mutez then failwith Errors.insufficient_swap_fee else

  let (current_batch, current_batch_set) = Batch.get_current_batch pair current_time storage.batch_set in
  let storage = { storage with batch_set = current_batch_set } in
  if Batch.can_deposit current_batch then
     let current_batch_number = current_batch.batch_number in
     let next_order_number = storage.last_order_number + 1n in
     let order : order = external_to_order external_order next_order_number current_batch_number storage.valid_tokens storage.valid_swaps in
     (* We intentionally limit the amount of distinct orders that can be placed whilst unredeemed orders exist for a given user  *)
     if Ubot.is_within_limit order.trader storage.user_batch_ordertypes then
       let new_orderbook = Big_map.add next_order_number order storage.orderbook in
       let new_ubot = Ubot.add_order order.trader current_batch_number order storage.user_batch_ordertypes in
       let updated_volumes = Batch.update_volumes order current_batch in
       let updated_batches = Big_map.update current_batch_number (Some updated_volumes) current_batch_set.batches in
       let updated_batch_set = { current_batch_set with batches = updated_batches } in
       let updated_storage = {
         storage with batch_set = updated_batch_set;
         orderbook = new_orderbook;
         last_order_number = next_order_number;
         user_batch_ordertypes = new_ubot; } in
       let fee_recipient = storage.fee_recipient in
       let treasury_ops = Treasury.deposit order.trader order.swap.from fee_recipient fee_amount_in_mutez in
       (treasury_ops, updated_storage)

      else
        failwith Errors.too_many_unredeemed_orders
  else
    failwith Errors.no_open_batch_for_deposits

let redeem
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)

(* Post the rate in the contract and check if the current batch of orders needs to be cleared. *)
let post_rate (rate : rate) (storage : storage) : result =
  let validated_swap = validate Buy rate.swap storage.valid_tokens storage.valid_swaps in
  let rate  = { rate with swap = validated_swap; } in
  let storage = Pricing.Rates.post_rate rate storage in
  let pair = Types.Utils.pair_of_rate rate in
  let current_time = Tezos.get_now () in
  let (batch, current_batch_set) = Batch.get_current_batch pair current_time storage.batch_set in
  let current_batch_set = finalize batch current_time rate current_batch_set in
  let storage = { storage with batch_set = current_batch_set } in
  no_op (storage)


let change_fee
    (new_fee: tez)
    (storage: storage) : result =
    let () = is_administrator storage in
    let storage = { storage with fee_in_mutez = new_fee; } in
    no_op (storage)

let change_admin_address
    (new_admin_address: address)
    (storage: storage) : result =
    let _ = is_administrator storage in
    let storage = { storage with administrator = new_admin_address; } in
    no_op (storage)


let main
  (action, storage : entrypoint * storage) : result =
  match action with
   | Deposit order -> deposit order storage
   | Post new_rate -> post_rate new_rate storage
   | Redeem -> redeem storage
   | Change_fee new_fee -> change_fee new_fee storage
   | Change_admin_address new_admin_address -> change_admin_address new_admin_address storage


