#import "@ligo/math-lib/rational/rational.mligo" "Rational"
#include "types.mligo"
#include "utils.mligo"
#include "errors.mligo"
#include "constants.mligo"

module BatchHoldings_Utils = struct

[@inline]
let increase_holding
  (batch_number: nat)
  (batches: batches): batches =
  match Big_map.find_opt batch_number batches with
  | None  -> failwith cannot_increase_holdings_of_batch_that_does_not_exist
  | Some b -> let bh = b.holdings + 1n in
              let b = { b with holdings = bh; } in
              Big_map.update batch_number (Some b) batches

[@inline]
let add_batch_holding
  (batch_number: nat)
  (address: address)
  (ubots: user_batch_ordertypes)
  (batches: batches): batches =
  match Big_map.find_opt address ubots with
  | Some bots -> (match Map.find_opt batch_number bots with
                  | Some _ -> batches
                  | None   -> increase_holding batch_number batches)
  | None -> increase_holding batch_number batches

[@inline]
let remove_batch_holding
  (batch_number: nat)
  (batches: batches): batches =
  match Big_map.find_opt batch_number batches with
  | None -> failwith cannot_decrease_holdings_of_removed_batch
  | Some b -> let nh = abs(b.holdings - 1n) in
              let b = { b with holdings = nh; } in
              Big_map.update batch_number (Some b) batches


[@inline]
let can_batch_be_removed
  (batch_number: nat)
  (batches: batches): bool =
  match Big_map.find_opt batch_number batches with
                | None -> failwith cannot_decrease_holdings_of_removed_batch
                | Some b -> b.holdings <= 0n

end


module Storage = struct

  type t = {
    metadata: metadata;
    rates_current : rates_current;
    batch_set : batch_set;
    last_order_number : nat;
    user_batch_ordertypes: user_batch_ordertypes;
    fee_in_mutez: tez;
    fee_recipient : address;
    administrator : address;
    tokenmanager : address;
    marketmaker : address;
    limit_on_tokens_or_pairs : nat;
    deposit_time_window_in_seconds : nat;
  }

end

module OrderType = struct

[@inline]
let make
    (order: swap_order) : ordertype =
    {
      tolerance = order.tolerance;
      side = order.side;
    }

end

module OrderTypes = struct

[@inline]
let make
    (order: swap_order) : ordertypes =
    let ot = OrderType.make order in
    let new_map = (Map.empty : ordertypes) in
    Map.add ot order.swap.from.amount new_map

[@inline]
let update
    (order: swap_order)
    (bot: ordertypes) : ordertypes =
    let ot: ordertype = OrderType.make order in
    match Map.find_opt ot bot with
    | None -> Map.add ot order.swap.from.amount bot
    | Some amt -> let new_amt = amt + order.swap.from.amount in
                  Map.update ot (Some new_amt) bot

[@inline]
let count
  (ots: ordertypes) : nat = Map.size ots

end

module Batch_OrderTypes = struct

[@inline]
let make
  (batch_id: nat)
  (order: swap_order): batch_ordertypes =
  let new_ot : ordertypes  = OrderTypes.make order in
  Map.literal [(batch_id, new_ot)]

[@inline]
let add_or_update
  (batch_id: nat)
  (order: swap_order)
  (bots: batch_ordertypes): batch_ordertypes =
  match Map.find_opt batch_id bots with
  | None -> let new_ot: ordertypes = OrderTypes.make order in
            Map.add batch_id new_ot bots
  | Some bot -> let updated_bot : ordertypes = OrderTypes.update order bot in
                Map.update batch_id (Some updated_bot) bots

[@inline]
let count
  (bots: batch_ordertypes) : nat =
  let count_aux
    (acc, (_batch_number, ots): nat * (nat * ordertypes)) : nat =
    let ots_count = OrderTypes.count ots in
    acc + ots_count
  in
  Map.fold count_aux bots 0n

end

module Redemption_Utils = struct

[@inline]
let was_in_clearing_for_buy
  (clearing_tolerance: tolerance)
  (order_tolerance: tolerance) : bool =
    match order_tolerance, clearing_tolerance with
    | Exact,Minus -> false
    | Plus,Minus -> false
    | Minus,Exact -> true
    | Plus,Exact -> false
    | Minus,Plus -> true
    | Exact,Plus -> true
    | _,_ -> true

[@inline]
let was_in_clearing_for_sell
  (clearing_tolerance: tolerance)
  (order_tolerance: tolerance) : bool =
    match order_tolerance, clearing_tolerance with
    | Exact,Minus -> true
    | Plus,Minus -> true
    | Minus,Exact -> false
    | Plus,Exact -> true
    | Minus,Plus -> false
    | Exact,Plus -> false
    | _,_ -> true

[@inline]
let was_in_clearing
  (volumes:volumes)
  (ot: ordertype)
  (clearing: clearing) : bool =
  if volumes.buy_total_volume = 0n then false else
  if volumes.sell_total_volume = 0n then false else
  let order_tolerance = ot.tolerance in
  let order_side = ot.side in
  let clearing_tolerance = clearing.clearing_tolerance in
  match order_side with
  | Buy -> was_in_clearing_for_buy clearing_tolerance order_tolerance
  | Sell -> was_in_clearing_for_sell clearing_tolerance order_tolerance


[@inline]
let get_clearing_volume
  (clearing:clearing) : nat =
  match clearing.clearing_tolerance with
  | Minus -> clearing.clearing_volumes.minus
  | Exact -> clearing.clearing_volumes.exact
  | Plus -> clearing.clearing_volumes.plus

(* Filter 0 amount transfers out *)
[@inline]
let add_payout_if_not_zero
  (payout: token_amount)
  (tam: token_amount_map) : token_amount_map =
  if payout.amount > 0n then
    TokenAmountMap.increase payout tam
  else
    tam

[@inline]
let get_cleared_sell_side_payout
  (from: token)
  (to: token)
  (amount: nat)
  (clearing: clearing)
  (tam: token_amount_map ): token_amount_map =
  let tc = clearing.total_cleared_volumes in
  (* Find the buy side volume in buy token units that was cleared.  This doesn't include all the volume that was subject to clearing, but just that which can be cleared on both sides of the trade  *)
  let f_buy_side_cleared_volume = Rational.new (int tc.buy_side_total_cleared_volume) in
  (* Find the sell side volume in sell token units that was included in the clearing.  This doesn't not include the volume of any orders that were outside the price *)
  (* This will be used to calculate the prorata allocation of the order amount against the volume that was included in clearing *)
  let f_sell_side_volume_subject_to_clearing = Rational.new (int tc.sell_side_volume_subject_to_clearing) in
  (* Represent the amount of user sell order as a rational *)
  let f_amount = Rational.new (int amount) in
  (* The pro rata allocation of the user's order amount in the context of the cleared volume.  This is represented as a percentage of the total volume that was subject to clearing *)
  let prorata_allocation = Rational.div f_amount f_sell_side_volume_subject_to_clearing in
  (* Given the buy side volume that is available to settle the order, calculate the payout in buy tokens for the prorata amount  *)
  let payout = Rational.mul prorata_allocation f_buy_side_cleared_volume in
  (* Given the buy side payout, calculate in sell side units so the remainder of a partial fill can be calculated *)
  let payout_equiv = Rational.mul payout clearing.clearing_rate.rate in
  (* Calculate the remaining amount on the sell side of a partial fill *)
  let remaining = Rational.sub f_amount payout_equiv in
  (* Build payout amount *)
  let fill_payout: token_amount = {
    token = to;
    amount = get_rounded_number_lower_bound payout;
  } in
  (* Add payout to transfers if not zero  *)
  let u_tam = add_payout_if_not_zero fill_payout tam in
  (* Check if there is a partial fill.  If so add partial fill payout plus remainder otherwise just add payout  *)
  if gt remaining (Rational.new 0) then
    let token_rem : token_amount = {
        token = from;
        amount = get_rounded_number_lower_bound remaining;
    } in
    TokenAmountMap.increase token_rem u_tam
  else
    u_tam

[@inline]
let get_cleared_buy_side_payout
  (from: token)
  (to: token)
  (amount: nat)
  (clearing:clearing)
  (tam: token_amount_map): token_amount_map =
  let tc = clearing.total_cleared_volumes in
  (* Find the sell side volume in sell token units that was cleared.  This doesn't include all the volume that was subject to clearing, but just that which can be cleared on both sides of the trade  *)
  let f_sell_side_cleared_volume = Rational.new (int tc.sell_side_total_cleared_volume) in
  (* Find the buy side volume that was included in the clearing.  This doesn't not include the volume of any orders that were outside the price *)
  let f_buy_side_actual_volume_subject_to_clearing = Rational.new (int tc.buy_side_volume_subject_to_clearing) in
  (* Represent the amount of user buy order as a rational *)
  let f_amount = Rational.new (int amount) in
  (* The pro rata allocation of the user's order amount in the context of the cleared volume.  This is represented as a percentage of the cleared total volume *)
  let prorata_allocation = Rational.div f_amount f_buy_side_actual_volume_subject_to_clearing in
  (* Given the sell side volume that is available to settle the order, calculate the payout in sell tokens for the prorata amount  *)
  let payout = Rational.mul prorata_allocation f_sell_side_cleared_volume in
  (* Given the sell side payout, calculate in buy side units so the remainder of a partial fill can be calculated *)
  let payout_equiv = Rational.div payout clearing.clearing_rate.rate in
  (* Calculate the remaining amount on the buy side of a partial fill *)
  let remaining = Rational.sub f_amount payout_equiv in
  (* Build payout amount *)
  let fill_payout = {
    token = to;
    amount = get_rounded_number_lower_bound payout;
  } in
  (* Add payout to transfers if not zero  *)
  let u_tam = add_payout_if_not_zero fill_payout tam in
  (* Check if there is a partial fill.  If so add partial fill payout plus remainder otherwise just add payout  *)
  if gt remaining (Rational.new 0) then
    let token_rem = {
        token = from;
        amount = get_rounded_number_lower_bound remaining;
    } in
    TokenAmountMap.increase token_rem u_tam
  else
    u_tam

[@inline]
let get_cleared_payout
  (ot: ordertype)
  (amt: nat)
  (clearing: clearing)
  (tam: token_amount_map)
  (tokens: ValidTokens.t_map): token_amount_map =
  let s = ot.side in
  let swap = clearing.clearing_rate.swap in
  let from_token = get_token_from_map swap.from tokens in
  let to_token = get_token_from_map swap.to tokens in
  match s with
  | Buy -> get_cleared_buy_side_payout from_token to_token amt clearing tam
  | Sell -> get_cleared_sell_side_payout to_token from_token amt clearing tam


[@inline]
let collect_order_payout_from_clearing
  ((c, tam, vols, tokens, fees, fee_in_mutez, market_vault_used), (ot, amt): (clearing * token_amount_map * volumes * ValidTokens.t_map * fees * tez * bool) * (ordertype * nat)) :  (clearing * token_amount_map * volumes * ValidTokens.t_map * fees * tez * bool) =
  let (u_tam, u_fees) = if was_in_clearing vols ot c then
                          let tm = get_cleared_payout ot amt c tam tokens in
                          if market_vault_used then
                            let f = fees.to_market_maker + fee_in_mutez in
                            let uf = { fees with to_market_maker = f; } in
                            (tm, uf)
                          else
                            let f = fees.to_send + fee_in_mutez in
                            let uf = { fees with to_send = f; } in
                            (tm, uf)
                        else
                          let ta: token_amount = TokenAmount.recover ot amt c tokens in
                          let f = fees.to_refund + fee_in_mutez in
                          let uf = { fees with to_refund = f; } in
                          (TokenAmountMap.increase ta tam, uf)
  in
  (c, u_tam, vols, tokens, u_fees, fee_in_mutez, market_vault_used)

end

module Ubots = struct

[@inline]
let add_order
    (holder: address)
    (batch_id: nat)
    (order : swap_order)
    (ubots: user_batch_ordertypes) : user_batch_ordertypes =
    match Big_map.find_opt holder ubots with
    | None -> let new_bots = Batch_OrderTypes.make batch_id order in
              Big_map.add holder new_bots ubots
    | Some bots -> let updated_bots = Batch_OrderTypes.add_or_update batch_id order bots in
                   Big_map.update holder (Some updated_bots) ubots

[@inline]
let get_clearing
   (batch: batch) : clearing option =
   match batch.status with
   | Cleared ci -> Some ci.clearing
   | _ -> None


[@inline]
let collect_redemptions
    ((bots, tam, bts, tokens, fees, fee_in_mutez),(batch_number,otps) : (batch_ordertypes * token_amount_map * batch_set * ValidTokens.t_map * fees * tez) * (nat * ordertypes)) : (batch_ordertypes * token_amount_map * batch_set * ValidTokens.t_map * fees * tez) =
    let batches = bts.batches in
    match Big_map.find_opt batch_number batches with
    | None -> bots, tam, bts, tokens, fees, fee_in_mutez
    | Some batch -> (match get_clearing batch with
                      | None -> bots, tam, bts, tokens, fees, fee_in_mutez
                      | Some c -> let _c, u_tam, _vols, _tokns, fs, _fim, _mvu = Map.fold Redemption_Utils.collect_order_payout_from_clearing otps (c, tam, batch.volumes, tokens, fees, fee_in_mutez, batch.market_vault_used)  in
                                  let batches = BatchHoldings_Utils.remove_batch_holding batch.batch_number batches in
                                  let bts = if BatchHoldings_Utils.can_batch_be_removed batch.batch_number batches then
                                              let batches = Big_map.remove batch.batch_number bts.batches in
                                              { bts with batches = batches;  }
                                            else
                                              { bts with batches = batches;  }
                                  in
                                  let u_bots = Map.remove batch_number bots in
                                  u_bots,u_tam, bts, tokens, fs, fee_in_mutez)

[@inline]
let collect_redemption_payouts
    (holder: address)
    (fees: fees)
    (specific_batch_opt:nat option)
    (storage: Storage.t):  (fees * user_batch_ordertypes * batch_set * token_amount_map) =
    let fee_in_mutez = storage.fee_in_mutez in
    let batch_set = storage.batch_set in
    let ubots = storage.user_batch_ordertypes in
    let tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in
    let empty_tam = (Map.empty : token_amount_map) in
    match Big_map.find_opt holder ubots with
    | None -> fees, ubots, batch_set, empty_tam
    | Some bots -> let u_bots, u_tam, bs, _tkns, u_fees, _fim = match specific_batch_opt with
                                                                | Some sb -> (match Map.find_opt sb bots  with
                                                                              | None -> (bots, empty_tam, batch_set, tokens, fees, fee_in_mutez)
                                                                              | Some opts -> collect_redemptions ((bots, empty_tam, batch_set, tokens, fees, fee_in_mutez),(sb,opts)))
                                                                | None ->   Map.fold collect_redemptions bots (bots, empty_tam, batch_set, tokens, fees, fee_in_mutez) 
                   in
                   let updated_ubots = Big_map.update holder (Some u_bots) ubots in
                   u_fees, updated_ubots,  bs, u_tam


[@inline]
let is_within_limit
  (holder: address)
  (ubots: user_batch_ordertypes) : bool =
  match Big_map.find_opt holder ubots with
  | None  -> true
  | Some bots -> let outstanding_token_items = Batch_OrderTypes.count bots in
                 outstanding_token_items <= limit_of_redeemable_items

end




module Treasury = struct

type storage = Storage.t


[@inline]
let resolve_fees
  (fees: fees)
  (token_ops: operation list): operation list =
  let token_ops =
    if fees.to_refund > 0mutez then
      Treasury_Utils.transfer_fee fees.payer fees.to_refund :: token_ops
    else
      token_ops
  in
  let token_ops =
    if fees.to_market_maker > 0mutez then
      Treasury_Utils.transfer_fee fees.market_maker fees.to_market_maker :: token_ops
    else
      token_ops
  in
  if fees.to_send > 0mutez then
    Treasury_Utils.transfer_fee fees.recipient fees.to_send :: token_ops
  else
    token_ops

[@inline]
let deposit
    (deposit_address : address)
    (deposited_token : token_amount) : operation list  =
      let treasury_vault = get_vault () in
      let deposit_op = Treasury_Utils.handle_transfer deposit_address treasury_vault deposited_token in
      [ deposit_op]

[@inline]
let redeem_by_batch
    (redeem_address : address)
    (batch_id: nat)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_vault () in
      let fees = {
        to_send = 0mutez;
        to_refund = 0mutez;
        to_market_maker = 0mutez;
        payer = redeem_address;
        recipient = storage.fee_recipient;
        market_maker = storage.marketmaker;
      } in
      let fees, updated_ubots, updated_batch_set,  payout_token_map = Ubots.collect_redemption_payouts redeem_address fees (Some batch_id) storage in
      let operations = Treasury_Utils.transfer_holdings treasury_vault redeem_address payout_token_map in
      let operations = resolve_fees fees operations in
      let updated_storage = { storage with user_batch_ordertypes = updated_ubots; batch_set = updated_batch_set;  } in
      (operations, updated_storage)

[@inline]
let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_vault () in
      let fees = {
        to_send = 0mutez;
        to_refund = 0mutez;
        to_market_maker = 0mutez;
        payer = redeem_address;
        recipient = storage.fee_recipient;
        market_maker = storage.marketmaker;
      } in
      let fees, updated_ubots, updated_batch_set,  payout_token_map = Ubots.collect_redemption_payouts redeem_address fees None storage in
      let operations = Treasury_Utils.transfer_holdings treasury_vault redeem_address payout_token_map in
      let operations = resolve_fees fees operations in
      let updated_storage = { storage with user_batch_ordertypes = updated_ubots; batch_set = updated_batch_set;  } in
      (operations, updated_storage)

end

module Token_Utils = struct

[@inline]
let is_valid_swap_pair
  (side: side)
  (swap: swap_reduced)
  (valid_swaps: ValidSwaps.t_map): swap_reduced =
  let token_pair = pair_of_swap side swap in
  let rate_name = get_rate_name_from_pair token_pair in
  if Map.mem rate_name valid_swaps then swap else failwith unsupported_swap_type

[@inline]
let remove_token_old
  (token: token)
  (valid_tokens: ValidTokens.t) : ValidTokens.t =
  match ValidTokens.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             ValidTokens.remove token.name valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> valid_tokens

[@inline]
let add_token
  (token: token)
  (valid_tokens: ValidTokens.t) : ValidTokens.t =
  match ValidTokens.find_opt token.name valid_tokens with
  | Some existing_token -> if are_equivalent_tokens existing_token token then
                             valid_tokens
                           else
                             failwith token_already_exists_but_details_are_different
  | None -> ValidTokens.upsert token.name token valid_tokens

[@inline]
let is_token_used
  (token: token)
  (valid_tokens: ValidTokens.t) : bool =
  let is_token_in_tokens (acc, (_i, t) : bool * (string * token)) : bool =
    are_equivalent_tokens token t ||
    acc
  in
  ValidTokens.fold is_token_in_tokens valid_tokens false

[@inline]
let is_token_used_in_swaps
  (token: token)
  (valid_swaps: ValidSwaps.t)
  (tokens: ValidTokens.t): bool =
  let is_token_used_in_swap (acc, (_i, valid_swap) : bool * (string * valid_swap_reduced)) : bool =
    let swap = valid_swap.swap in
    let to_token = get_token swap.to tokens in
    let from_token = get_token swap.from tokens in
    are_equivalent_tokens token to_token ||
    are_equivalent_tokens token from_token ||
    acc
  in
  ValidSwaps.fold is_token_used_in_swap valid_swaps false

end

module Batch_Utils = struct

type batch_status =
  | Open of { start_time : timestamp }
  | Closed of { start_time : timestamp ; closing_time : timestamp }
  | Cleared of { at : timestamp; clearing : clearing; rate : exchange_rate }


[@inline]
let is_batch_open
  (batch:batch): bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


[@inline]
let reduce_volumes
  (ots: ordertypes)
  (volumes:volumes): volumes =
  let reduce_volume_for_ot (vols, (ot, amt) : volumes * (ordertype * nat)) : volumes =
    let side = ot.side in
    let tolerance = ot.tolerance in
    match side with
    | Buy -> let total_buy_side_volume = abs(vols.buy_total_volume - amt)
             in
             (match tolerance with
              | Minus -> { vols with buy_minus_volume = abs(vols.buy_minus_volume - amt); buy_total_volume = total_buy_side_volume; }
              | Exact -> { vols with buy_exact_volume = abs(vols.buy_exact_volume - amt);  buy_total_volume = total_buy_side_volume; }
              | Plus -> { vols with buy_plus_volume = abs(vols.buy_plus_volume - amt);  buy_total_volume = total_buy_side_volume; })
    | Sell -> let total_sell_side_volume = abs(vols.sell_total_volume - amt)
              in
              (match tolerance with
               | Minus -> { vols with sell_minus_volume = abs(vols.sell_minus_volume - amt); sell_total_volume = total_sell_side_volume; }
               | Exact -> { vols with sell_exact_volume = abs(vols.sell_exact_volume - amt);  sell_total_volume = total_sell_side_volume; }
               | Plus -> { vols with sell_plus_volume = abs(vols.sell_plus_volume - amt);  sell_total_volume = total_sell_side_volume; })
  in
  Map.fold reduce_volume_for_ot ots volumes


[@inline]
let set_buy_side_volume
  (order: swap_order)
  (volumes : volumes) : volumes =
  let total_buy_side_volume = volumes.buy_total_volume + order.swap.from.amount in
  match order.tolerance with
  | Minus -> { volumes with buy_minus_volume = volumes.buy_minus_volume + order.swap.from.amount; buy_total_volume = total_buy_side_volume; }
  | Exact -> { volumes with buy_exact_volume = volumes.buy_exact_volume + order.swap.from.amount;  buy_total_volume = total_buy_side_volume; }
  | Plus -> { volumes with buy_plus_volume = volumes.buy_plus_volume + order.swap.from.amount;  buy_total_volume = total_buy_side_volume; }

[@inline]
let set_sell_side_volume
  (order: swap_order)
  (volumes : volumes) : volumes =
 let total_sell_side_volume = volumes.sell_total_volume + order.swap.from.amount in
  match order.tolerance with
  | Minus -> { volumes with sell_minus_volume = volumes.sell_minus_volume + order.swap.from.amount; sell_total_volume = total_sell_side_volume; }
  | Exact -> { volumes with sell_exact_volume = volumes.sell_exact_volume + order.swap.from.amount;  sell_total_volume = total_sell_side_volume; }
  | Plus -> { volumes with sell_plus_volume = volumes.sell_plus_volume + order.swap.from.amount;  sell_total_volume = total_sell_side_volume; }

[@inline]
let make
  (batch_number: nat)
  (timestamp: timestamp)
  (pair: pair) : batch =
  let volumes: volumes = {
      buy_minus_volume = 0n;
      buy_exact_volume = 0n;
      buy_plus_volume = 0n;
      buy_total_volume = 0n;
      sell_minus_volume = 0n;
      sell_exact_volume = 0n;
      sell_plus_volume = 0n;
      sell_total_volume = 0n;
    } in
  {
    batch_number= batch_number;
    status = Open { start_time = timestamp } ;
    pair = pair;
    volumes = volumes;
    holdings = 0n;
    market_vault_used = false;
  }

[@inline]
let update_current_batch_in_set
  (batch : batch)
  (batch_set : batch_set) : (batch * batch_set)=
  let updated_batches = Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let name = get_rate_name_from_pair batch.pair in
  let updated_batch_indices = Map.update name (Some batch.batch_number) batch_set.current_batch_indices in
  batch, { batch_set with batches = updated_batches; current_batch_indices = updated_batch_indices; }

[@inline]
let should_be_cleared
  (batch : batch)
  (current_time : timestamp) : bool =
  match batch.status with
    | Closed { start_time = _; closing_time } ->
      current_time > closing_time + price_wait_window_in_seconds
    | _ -> false


[@inline]
let is_cleared
  (batch: batch) : bool =
  match batch.status with
  | Cleared _ -> true
  | _ -> false

[@inline]
let start_period
  (pair : pair)
  (batch_set : batch_set)
  (current_time : timestamp) : (batch * batch_set) =
  let highest_batch_index = get_highest_batch_index batch_set.current_batch_indices in
  let new_batch_number = highest_batch_index + 1n in
  let new_batch = make new_batch_number current_time pair in
  update_current_batch_in_set new_batch batch_set

[@inline]
let close
(deposit_time_window: nat)
(batch : batch)
(storage: Storage.t): Storage.t * batch =
  match batch.status with
    | Open { start_time } ->
      let batch_close_time = start_time + (int deposit_time_window) in
      let new_status = Closed { start_time = start_time; closing_time = batch_close_time } in
      storage,{ batch with status = new_status }
    | _ -> failwith trying_to_close_batch_which_is_not_open

[@inline]
let new_batch_set : batch_set =
  {
    current_batch_indices = (Map.empty: (string, nat) map);
    batches= (Big_map.empty: (nat, batch) big_map);
  }

[@inline]
let progress_batch
  (deposit_time_window: nat)
  (pair: pair)
  (batch: batch)
  (batch_set: batch_set)
  (storage: Storage.t)
  (current_time : timestamp) : (batch * batch_set * Storage.t) =
  match batch.status with
  | Open { start_time } ->
    if  current_time >= start_time + (int deposit_time_window) then
      let (storage,closed_batch) = close deposit_time_window batch storage in
      let (b,bs) = update_current_batch_in_set closed_batch batch_set in
      (b,bs,storage)
    else
      (batch, batch_set,storage)
  | Closed { closing_time =_ ; start_time = _} ->
    (*  Batches can only be cleared on receipt of rate so here they should just be returned *)
    (batch, batch_set,storage)
  | Cleared _ -> let  (b,bs) = start_period pair batch_set current_time in
                  (b,bs,storage)


[@inline]
let update_volumes
  (order: swap_order)
  (batch : batch)  : batch =
  let vols = batch.volumes in
  let updated_vols = match order.side with
                     | Buy -> set_buy_side_volume order vols
                     | Sell -> set_sell_side_volume order vols
  in
  { batch with volumes = updated_vols;  }


[@inline]
let can_deposit
  (batch:batch) : bool =
  match batch.status with
  | Open _ -> true
  | _ -> false


[@inline]
let can_be_finalized
  (batch : batch)
  (current_time : timestamp) : bool = should_be_cleared batch current_time

[@inline]
let finalize_batch
  (batch : batch)
  (clearing: clearing)
  (current_time : timestamp)
  (rate : exchange_rate)
  (batch_set : batch_set): batch_set =
  let finalized_batch : batch = {
      batch with status = Cleared {
        at = current_time;
        clearing = clearing;
        rate = rate
      }
    } in
  let _, ucb = update_current_batch_in_set finalized_batch batch_set in
  ucb

[@inline]
let get_current_batch_without_opening
  (deposit_time_window: nat)
  (pair: pair)
  (current_time: timestamp)
  (storage: Storage.t)
  (batch_set: batch_set) : (batch option * batch_set * Storage.t) =
  let current_batch_index = get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  None, batch_set,storage
  | Some cb -> let is_cleared = is_cleared cb in
               if is_cleared then
                 Some cb, batch_set,storage
                else
                 let batch, batch_set, storage = progress_batch deposit_time_window pair cb batch_set storage current_time in
                 Some batch, batch_set, storage

[@inline]
let get_current_batch
  (deposit_time_window: nat)
  (pair: pair)
  (current_time: timestamp)
  (storage: Storage.t)
  (batch_set: batch_set) : (batch * batch_set * Storage.t) =
  let current_batch_index = get_current_batch_index pair batch_set.current_batch_indices in
  match Big_map.find_opt current_batch_index batch_set.batches with
  | None ->  let (b, bs) = start_period pair batch_set current_time in
             (b,bs,storage)
  | Some cb ->  progress_batch deposit_time_window pair cb batch_set storage current_time


let update_storage_with_order
    (order: swap_order)
    (next_order_number: nat)
    (current_batch_number: nat)
    (batch: batch)
    (batch_set: batch_set)
    (storage:Storage.t) : batch * Storage.t =
    let updated_volumes = update_volumes order batch in
    let updated_batches = Big_map.update current_batch_number (Some updated_volumes) batch_set.batches in
    let updated_batches = BatchHoldings_Utils.add_batch_holding current_batch_number order.trader storage.user_batch_ordertypes updated_batches in
    let new_ubot = Ubots.add_order order.trader current_batch_number order storage.user_batch_ordertypes in
    let updated_batch_set = { batch_set with batches = updated_batches } in
    updated_volumes, {
      storage with batch_set = updated_batch_set;
      last_order_number = next_order_number;
      user_batch_ordertypes = new_ubot;
    }


end

module Clearing = struct

(*
 Get the correct exchange rate based on the clearing price
*)
[@inline]
let get_clearing_rate
  (clearing: clearing)
  (exchange_rate: exchange_rate) : exchange_rate =
  match clearing.clearing_tolerance with
  | Exact -> exchange_rate
  | Plus -> let rate = Rational.mul (exchange_rate.rate) ten_bips_constant in
            { exchange_rate with rate = rate}
  | Minus -> let rate = Rational.div (exchange_rate.rate) ten_bips_constant in
             { exchange_rate with rate = rate}

[@inline]
let filter_volumes
  (volumes: volumes)
  (clearing: clearing) : (nat * nat) =
  match clearing.clearing_tolerance with
  | Minus -> let sell_vol = volumes.sell_minus_volume + volumes.sell_exact_volume + volumes.sell_plus_volume in
             volumes.buy_minus_volume , sell_vol
  | Exact -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume in
             let sell_vol = volumes.sell_exact_volume + volumes.sell_plus_volume in
             buy_vol, sell_vol
  | Plus -> let buy_vol = volumes.buy_minus_volume + volumes.buy_exact_volume + volumes.buy_plus_volume in
            buy_vol, volumes.sell_plus_volume

[@inline]
let compute_equivalent_amount (amount : nat) (rate : exchange_rate) (is_sell_side: bool) : nat =
  let float_amount = Rational.new (int (amount)) in
  if is_sell_side then
    get_rounded_number_lower_bound (Rational.div float_amount rate.rate)
  else
    get_rounded_number_lower_bound (Rational.mul float_amount rate.rate)

(*
  This function builds the order equivalence for the pro-rata redeemption.
*)
[@inline]
let build_total_cleared_volumes
  (volumes: volumes)
  (clearing : clearing)
  (rate : exchange_rate) : clearing =
  (* Collect the bid and ask amounts associated with the given clearing level.  Those volumes that are outside the clearing price are excluded *)
  let (buy_amounts_subject_to_clearing, ask_amounts_subject_to_clearing) = filter_volumes volumes clearing in
  (* Find the rate associated with the clearing point *)
  let clearing_rate = get_clearing_rate clearing rate in
  (* Find the volume in buy side units that can be cleared on both sides of the trade *)
  let buy_side_total_cleared_volume = match clearing.clearing_tolerance with
                                      | Minus -> clearing.clearing_volumes.minus
                                      | Exact -> clearing.clearing_volumes.exact
                                      | Plus -> clearing.clearing_volumes.plus
  in
  (* Convert cleared volume to sell side units to assist in payout claculations later *)
  let sell_side_total_cleared_volume_as_rational = Rational.mul (Rational.new (int buy_side_total_cleared_volume)) clearing_rate.rate in
  let sell_side_total_cleared_volume = get_rounded_number_lower_bound sell_side_total_cleared_volume_as_rational in
  (* Build total volumes objects which represents the TOTAL cleared volume on each side of the swap along which will be used in the payout calculations  *)
  let total_volumes = {
    buy_side_total_cleared_volume = buy_side_total_cleared_volume;
    buy_side_volume_subject_to_clearing = buy_amounts_subject_to_clearing;
    sell_side_total_cleared_volume = sell_side_total_cleared_volume;
    sell_side_volume_subject_to_clearing = ask_amounts_subject_to_clearing;
  } in
  { clearing with total_cleared_volumes = total_volumes; clearing_rate = clearing_rate }

[@inline]
let compute_clearing_prices
  (rate: exchange_rate)
  (current_batch : batch) : clearing =
  let volumes = current_batch.volumes in
  let sell_cp_minus = int (volumes.sell_minus_volume) in
  let sell_cp_exact = int (volumes.sell_exact_volume) in
  let sell_cp_plus = int (volumes.sell_plus_volume) in
  let buy_cp_minus = int (volumes.buy_minus_volume) in
  let buy_cp_exact = int (volumes.buy_exact_volume) in
  let buy_cp_plus = int (volumes.buy_plus_volume) in
  let buy_side : buy_side = buy_cp_minus, buy_cp_exact, buy_cp_plus in
  let sell_side : sell_side = sell_cp_minus, sell_cp_exact, sell_cp_plus in
  let clearing = get_clearing_price rate buy_side sell_side in
  let with_total_cleared_vols = build_total_cleared_volumes volumes clearing rate in
  with_total_cleared_vols

end



type storage  = Storage.t
type result = operation list * storage

[@inline]
let no_op (s : storage) : result =  (([] : operation list), s)

type entrypoint =
  | Deposit of external_swap_order
  | Tick of string
  | Redeem
  | RedeemByBatch of nat
  | Cancel of pair
  | Change_fee of tez
  | Change_admin_address of address
  | Change_marketmaker_address of address
  | Change_fee_recipient_address of address
  | Add_or_update_metadata of metadata_update
  | Remove_metadata of string
  | Change_deposit_time_window of nat


[@inline]
let get_oracle_price
  (failure_code: nat)
  (valid_swap: valid_swap_reduced) : orace_price_update =
  match Tezos.call_view "getPrice" valid_swap.oracle_asset_name valid_swap.oracle_address with
  | Some opu -> opu
  | None -> failwith failure_code


[@inline]
let admin_and_fee_recipient_address_are_different
  (admin : address)
  (fee_recipient : address ): unit =
  if admin = fee_recipient then failwith admin_and_fee_recipient_address_cannot_be_the_same else ()


[@inline]
let finalize
  (batch : batch)
  (current_time : timestamp)
  (rate : exchange_rate)
  (batch_set : batch_set): batch_set =
  if Batch_Utils.can_be_finalized  batch current_time then
    let current_time = Tezos.get_now () in
    let clearing : clearing = Clearing.compute_clearing_prices rate batch in
    Batch_Utils.finalize_batch batch clearing current_time rate batch_set
  else
    batch_set

[@inline]
let external_to_order
  (order: external_swap_order)
  (order_number: nat)
  (batch_number: nat)
  (valid_tokens: ValidTokens.t_map)
  (valid_swaps: ValidSwaps.t_map): swap_order =
  let side = nat_to_side order.side in
  let tolerance = nat_to_tolerance order.tolerance in
  let sender = Tezos.get_sender () in
  let converted_order : swap_order =
    {
      order_number = order_number;
      batch_number = batch_number;
      trader = sender;
      swap  = order.swap;
      side = side;
      tolerance = tolerance;
      redeemed = false;
    } in
  let _ = Tokens.validate_from_map side order.swap valid_tokens valid_swaps in
  converted_order

[@inline]
let get_valid_swap_reduced
 (pair_name: string)
 (storage : storage) : valid_swap_reduced =
 let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in
 match Map.find_opt pair_name valid_swaps with
 | Some vswp -> vswp
 | None -> failwith swap_does_not_exist

[@inline]
let remove_orders_from_batch
  (ots: ordertypes)
  (batch: batch): batch =
  let volumes = Batch_Utils.reduce_volumes ots batch.volumes in
  let holdings = abs (batch.holdings - 1n) in
  { batch with volumes = volumes; holdings= holdings; }

[@inline]
let remove_orders
  (ot: ordertypes)
  (batch:batch)
  (batch_set: batch_set)
  (storage: storage) =
  let batch = remove_orders_from_batch ot batch in
  let batches =  Big_map.update batch.batch_number (Some batch) batch_set.batches in
  let batch_set = { batch_set with batches = batches } in
  let storage = {storage with batch_set = batch_set} in
  storage

[@inline]
let remove_order_types
  (batch_number: nat)
  (holder: address)
  (bot: batch_ordertypes)
  (storage:storage) : ordertypes * storage =
  match Map.find_opt batch_number bot with
  | None -> failwith no_orders_for_user_address
  | Some ots -> let bot = Map.remove batch_number bot in
                let ubots = Big_map.update holder (Some bot) storage.user_batch_ordertypes in
                let storage = { storage with user_batch_ordertypes = ubots;} in
                (ots,storage)

[@inline]
let refund_orders
  (refund_address: address)
  (ots: ordertypes)
  (valid_swap:valid_swap)
  (storage: storage): result =
  let fee = storage.fee_in_mutez in
  let collect_refunds ((tam,mutez_to_ref), (ot, amt): ((token_amount_map * tez) * (ordertype * nat))) : (token_amount_map * tez) =
    let token  = match ot.side with
                 | Buy -> valid_swap.swap.from.token
                 | Sell -> valid_swap.swap.to
    in
    let ta = {
       token = token;
       amount = amt;
    } in
    let tam = TokenAmountMap.increase ta tam in
    let mutez_to_ref = mutez_to_ref + fee in
    tam, mutez_to_ref
  in
  let token_refunds, tez_refunds= Map.fold collect_refunds ots ((Map.empty: token_amount_map), 0mutez) in
  let treasury_vault = get_vault () in
  let operations = Treasury_Utils.transfer_holdings treasury_vault refund_address token_refunds in
  let operations = if tez_refunds > 0mutez then Treasury_Utils.transfer_fee storage.fee_recipient tez_refunds :: operations else operations in
  operations, storage

[@inline]
let cancel_order
  (pair: pair)
  (holder: address)
  (valid_swap: valid_swap)
  (storage: storage) : result =
  let ubots = storage.user_batch_ordertypes in
  let current_time = Tezos.get_now () in
  let (batch, batch_set, storage) = Batch_Utils.get_current_batch storage.deposit_time_window_in_seconds pair current_time storage storage.batch_set in
  let () = if not (Batch_Utils.is_batch_open batch) then failwith cannot_cancel_orders_for_a_batch_that_is_not_open in
  match Big_map.find_opt holder ubots with
  | None -> failwith no_orders_for_user_address
  | Some bot -> let orders_to_remove, storage = remove_order_types batch.batch_number holder bot storage in
                let storage = remove_orders orders_to_remove batch batch_set storage in
                refund_orders holder orders_to_remove valid_swap storage

[@inline]
let cancel
  (pair: pair)
  (storage: storage): result =
  let () = reject_if_tez_supplied () in
  let sender = Tezos.get_sender () in
  let token_one, token_two = pair in
  let pair_name = find_lexicographical_pair_name token_one token_two in
  let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in
  match Map.find_opt pair_name valid_swaps with
  | None -> failwith swap_does_not_exist
  | Some vswpr -> let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in
                  let vswp = valid_swap_reduced_to_valid_swap vswpr 1n valid_tokens in
                  cancel_order pair sender vswp storage

[@inline]
let oracle_price_is_not_stale
  (deposit_time_window: nat)
  (oracle_price_timestamp: timestamp) : unit =
  let dtw_i = int deposit_time_window in
  if (Tezos.get_now () - dtw_i) < oracle_price_timestamp then () else failwith oracle_price_is_stale

[@inline]
let is_oracle_price_newer_than_current
  (rate_name: string)
  (oracle_price_timestamp: timestamp)
  (storage: storage): unit =
  let rates = storage.rates_current in
  match Big_map.find_opt rate_name rates with
  | Some r -> if r.when >=oracle_price_timestamp then failwith oracle_price_is_not_timely
  | None   -> ()


[@inline]
let confirm_oracle_price_is_available_before_deposit
  (pair:pair)
  (batch:batch)
  (storage:storage) : unit =
  if Batch_Utils.is_batch_open batch then () else
  let pair_name = get_rate_name_from_pair pair in
  let valid_swap_reduced = get_valid_swap_reduced pair_name storage in
  let (lastupdated, _price)  = get_oracle_price oracle_price_should_be_available_before_deposit valid_swap_reduced in
  oracle_price_is_not_stale storage.deposit_time_window_in_seconds lastupdated

[@inline]
let confirm_swap_pair_is_disabled_prior_to_removal
  (valid_swap:valid_swap) : unit =
  if valid_swap.is_disabled_for_deposits then () else failwith cannot_remove_swap_pair_that_is_not_disabled


[@inline]
let enforce_correct_side
  (order:external_swap_order)
  (valid_swap:valid_swap_reduced) : unit =
  let swap = order.swap in
  let side = nat_to_side order.side in
  match side with
  | Buy ->
    if swap.from.token.name = valid_swap.swap.from then () else failwith incorrect_side_specified
  | Sell ->
    if swap.from.token.name = valid_swap.swap.to then () else failwith incorrect_side_specified


(* Register a deposit during a valid (Open) deposit time; fails otherwise.
   Updates the current_batch if the time is valid but the new batch was not initialized. *)
[@inline]
let deposit (external_order: external_swap_order) (storage : storage) : result =
  let pair = pair_of_external_swap external_order in
  let current_time = Tezos.get_now () in
  let pair_name = get_rate_name_from_pair pair in
  let valid_swap = get_valid_swap_reduced pair_name storage in
  if valid_swap.is_disabled_for_deposits then failwith swap_is_disabled_for_deposits else
  let () = enforce_correct_side external_order valid_swap in
  let fee_amount_in_mutez = storage.fee_in_mutez in
  let fee_provided = Tezos.get_amount () in
  if fee_provided < fee_amount_in_mutez then failwith insufficient_swap_fee else
  if fee_provided > fee_amount_in_mutez then failwith more_tez_sent_than_fee_cost else
  let (current_batch, current_batch_set, storage) = Batch_Utils.get_current_batch storage.deposit_time_window_in_seconds pair current_time storage storage.batch_set in
  if Batch_Utils.can_deposit current_batch then
     let () = confirm_oracle_price_is_available_before_deposit pair current_batch storage in
     let storage = { storage with batch_set = current_batch_set } in
     let current_batch_number = current_batch.batch_number in
     let depositor = Tezos.get_sender () in
     let current_batch = if depositor = storage.marketmaker then
                            { current_batch with market_vault_used = true; }
                         else
                            current_batch
     in
     let next_order_number = storage.last_order_number + 1n in
     let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in 
     let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in 
     let order : swap_order = external_to_order external_order next_order_number current_batch_number valid_tokens valid_swaps in
     (* We intentionally limit the amount of distinct orders that can be placed whilst unredeemed orders exist for a given user  *)
     if Ubots.is_within_limit order.trader storage.user_batch_ordertypes then
       let _,updated_storage = Batch_Utils.update_storage_with_order order next_order_number current_batch_number current_batch current_batch_set storage in
       let treasury_ops = Treasury.deposit order.trader order.swap.from in
       (treasury_ops, updated_storage)

      else
        failwith too_many_unredeemed_orders
  else
    failwith no_open_batch

[@inline]
let redeem
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let () = reject_if_tez_supplied () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem holder storage in
  (tokens_transfer_ops, new_storage)

[@inline]
let redeem_by_batch
 (batch_id:nat)
 (storage : storage) : result =
  let holder = Tezos.get_sender () in
  let () = reject_if_tez_supplied () in
  let (tokens_transfer_ops, new_storage) = Treasury.redeem_by_batch holder batch_id storage in
  (tokens_transfer_ops, new_storage)


[@inline]
let tick_price
  (rate_name: string)
  (valid_swap : valid_swap)
  (storage : storage) : storage =
  let valid_swap_reduced = valid_swap_to_valid_swap_reduced valid_swap in
  let (lastupdated, price) = get_oracle_price unable_to_get_price_from_oracle valid_swap_reduced in
  let () = is_oracle_price_newer_than_current rate_name lastupdated storage in
  let () = oracle_price_is_not_stale storage.deposit_time_window_in_seconds lastupdated in
  let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in 
  let oracle_rate = convert_oracle_price valid_swap.oracle_precision valid_swap.swap lastupdated price valid_tokens in
  let rates_current = update_current_rate (rate_name) (oracle_rate) (storage.rates_current) in
  let storage = { storage with rates_current = rates_current; } in
  let pair = pair_of_rate oracle_rate in
  let current_time = Tezos.get_now () in
  let batch_set = storage.batch_set in
  let (batch_opt, batch_set, storage) = Batch_Utils.get_current_batch_without_opening storage.deposit_time_window_in_seconds pair current_time storage batch_set in
  match batch_opt with
  | Some b -> let batch_set = finalize b current_time oracle_rate batch_set in
              let storage = { storage with batch_set = batch_set } in
              storage
  | None ->   storage


[@inline]
let tick
 (rate_name: string)
 (storage : storage) : result =
 let () = reject_if_tez_supplied () in
 let valid_swaps = TokenManagerUtils.get_valid_swaps storage.tokenmanager in
 match Map.find_opt rate_name valid_swaps with
 | Some vswpr -> let valid_tokens = TokenManagerUtils.get_valid_tokens storage.tokenmanager in
                 let vswp = valid_swap_reduced_to_valid_swap vswpr 1n valid_tokens in
                 let storage = tick_price rate_name vswp storage in
                 no_op (storage)
 | None -> failwith swap_does_not_exist

[@inline]
let change_fee
    (new_fee: tez)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let storage = { storage with fee_in_mutez = new_fee; } in
    no_op storage

[@inline]
let change_admin_address
    (new_admin_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let () = admin_and_fee_recipient_address_are_different new_admin_address storage.fee_recipient in
    let storage = { storage with administrator = new_admin_address; } in
    no_op storage

[@inline]
let change_mm_address
    (new_marketmaker_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let () = admin_and_fee_recipient_address_are_different new_marketmaker_address storage.fee_recipient in
    let storage = { storage with marketmaker = new_marketmaker_address; } in
    no_op storage

[@inline]
let change_fee_recipient_address
    (new_fee_recipient_address: address)
    (storage: storage) : result =
    let () = is_administrator storage.administrator in
    let () = reject_if_tez_supplied () in
    let () = admin_and_fee_recipient_address_are_different new_fee_recipient_address storage.administrator in
    let storage = { storage with fee_recipient = new_fee_recipient_address; } in
    no_op storage


[@inline]
let add_or_update_metadata
  (metadata_update: metadata_update)
  (storage:storage) : result =
   let () = is_administrator storage.administrator in
   let () = reject_if_tez_supplied () in
  let updated_metadata = match Big_map.find_opt metadata_update.key storage.metadata with
                         | None -> Big_map.add metadata_update.key metadata_update.value storage.metadata
                         | Some _ -> Big_map.update metadata_update.key (Some metadata_update.value) storage.metadata
  in
  let storage = {storage with metadata = updated_metadata } in
  no_op storage

[@inline]
let remove_metadata
  (key: string)
  (storage:storage) : result =
   let () = is_administrator storage.administrator in
   let () = reject_if_tez_supplied () in
  let updated_metadata = Big_map.remove key storage.metadata in
  let storage = {storage with metadata = updated_metadata } in
  no_op storage


[@inline]
let change_deposit_time_window
  (new_window: nat)
  (storage: storage) : result =
  let () = is_administrator storage.administrator in
  let () = reject_if_tez_supplied () in
  if new_window < minimum_deposit_time_in_seconds then failwith cannot_update_deposit_window_to_less_than_the_minimum else
  if new_window > maximum_deposit_time_in_seconds then failwith cannot_update_deposit_window_to_more_than_the_maximum else
  let storage = { storage with deposit_time_window_in_seconds = new_window; } in
  no_op storage

[@view]
let get_fee_in_mutez ((), storage : unit * storage) : tez = storage.fee_in_mutez


[@view]
let redeemable_holdings_available ((), storage : unit * storage) : bool =
  let sender = Tezos.get_sender () in
  let find_non_zero_ordertype = fun (has,(_ot,v):bool * (ordertype * nat) ) -> has || v > 0n
  in
  let find_non_zero_holding = fun (has,(_bn,ots):bool * (nat * ordertypes) ) -> has || Map.fold find_non_zero_ordertype ots false
  in
  match Big_map.find_opt sender storage.user_batch_ordertypes with
  | None -> false
  | Some bots -> Map.fold find_non_zero_holding bots false

[@view]
let get_current_batches ((),storage: unit * storage) : batch list=
  let collect_batches (acc, (_s, i) :  batch list * (string * nat)) : batch list =
     match Big_map.find_opt i storage.batch_set.batches with
     | None   -> acc
     | Some b -> b :: acc
    in
    Map.fold collect_batches storage.batch_set.current_batch_indices []


let main
  (action, storage : entrypoint * storage) : operation list * storage =
  match action with
  (* User endpoints *)
   | Deposit order -> deposit order storage
   | Redeem -> redeem storage
   | RedeemByBatch i -> redeem_by_batch i  storage
   | Cancel pair -> cancel pair storage
  (* Maintenance endpoint *)
   | Tick r ->  tick r storage
  (* Admin endpoints *)
   | Change_fee new_fee -> change_fee new_fee storage
   | Change_admin_address new_admin_address -> change_admin_address new_admin_address storage
   | Change_marketmaker_address new_mm_address -> change_mm_address new_mm_address storage
   | Change_fee_recipient_address new_fee_recipient_address -> change_fee_recipient_address new_fee_recipient_address storage
   | Add_or_update_metadata mu -> add_or_update_metadata mu storage
   | Remove_metadata k -> remove_metadata k storage
   | Change_deposit_time_window t -> change_deposit_time_window t storage



