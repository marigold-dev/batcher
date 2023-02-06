#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"
#import "math.mligo" "Math"
#import "../math_lib/lib/rational.mligo" "Rational"

module Types = CommonTypes.Types
module Utils = CommonTypes.Utils
module TokenAmountMap = CommonTypes.TokenAmountMap
module TokenAmount = CommonTypes.TokenAmount
module RationalUtils = Math.RationalUtils


type ordertype = Types.ordertype
type batch_indices = Types.batch_indices
type tolerance = Types.tolerance
type clearing = Types.clearing
type batch = Types.batch
type swap = Types.swap
type token_amount = Types.token_amount
type ordertypes = Types.ordertypes
type batch_ordertypes = Types.batch_ordertypes
type order = Types.swap_order
type batch_set = Types.batch_set
type token_amount_map = Types.token_amount_map
type token = Types.token


module OrderType = struct

type t = ordertype

let make
    (order: order) : t =
    {
      tolerance = order.tolerance;
      side = order.side;
    }

end

module OrderTypes = struct

type t = ordertypes

let make
    (order: order) : t =
    let ot = OrderType.make order in
    let new_map = (Map.empty : t) in
    Map.add ot order.swap.from.amount new_map

let update
    (order: order)
    (bot: t) : t =
    let ot: OrderType.t = OrderType.make order in
    match Map.find_opt ot bot with
    | None -> Map.add ot order.swap.from.amount bot
    | Some amt -> let new_amt = amt + order.swap.from.amount in
                  Map.update ot (Some new_amt) bot

let count
  (ots: t) : nat = Map.size ots


end


module Batch_OrderTypes = struct

type t = batch_ordertypes

let make
  (batch_id: nat)
  (order: order): t =
  let new_ot : OrderTypes.t  = OrderTypes.make order in
  Map.literal [(batch_id, new_ot)]

let add_or_update
  (batch_id: nat)
  (order: order)
  (bots: t): t =
  match Map.find_opt batch_id bots with
  | None -> let new_ot: OrderTypes.t = OrderTypes.make order in
            let temp: t = Map.add batch_id new_ot bots in
            temp
  | Some bot -> let updated_bot : OrderTypes.t = OrderTypes.update order bot in
                let temp: t = Map.update batch_id (Some updated_bot) bots in
                temp


let count
  (bots: t) : nat =
  let count_aux
    (acc, (_batch_number, ots): nat * (nat * ordertypes)) : nat =
    let ots_count = OrderTypes.count ots in
    acc + ots_count
  in
  Map.fold count_aux bots 0n



end

module Redemption_Utils = struct

  let was_in_clearing_for_buy
   (clearing_tolerance: tolerance)
   (order_tolerance: tolerance) : bool =
      match (order_tolerance, clearing_tolerance) with
      | (EXACT,MINUS) -> true
      | (PLUS,MINUS) -> true
      | (MINUS,EXACT) -> false
      | (PLUS,EXACT) -> true
      | (MINUS,PLUS) -> false
      | (EXACT,PLUS) -> false
      | (_,_) -> true

  let was_in_clearing_for_sell
   (clearing_tolerance: tolerance)
   (order_tolerance: tolerance) : bool =
      match (order_tolerance, clearing_tolerance) with
      | (EXACT,MINUS) -> false
      | (PLUS,MINUS) -> false
      | (MINUS,EXACT) -> true
      | (PLUS,EXACT) -> false
      | (MINUS,PLUS) -> true
      | (EXACT,PLUS) -> true
      | (_,_) -> true

  let was_in_clearing
    (ot: ordertype)
    (clearing: clearing) : bool =
    let order_tolerance = ot.tolerance in
    let order_side = ot.side in
    let clearing_tolerance = clearing.clearing_tolerance in
    match order_side with
    | BUY -> was_in_clearing_for_buy clearing_tolerance order_tolerance
    | SELL -> was_in_clearing_for_sell clearing_tolerance order_tolerance


  let get_clearing_volume
    (clearing:clearing) : nat =
    match clearing.clearing_tolerance with
    | MINUS -> clearing.clearing_volumes.minus
    | EXACT -> clearing.clearing_volumes.exact
    | PLUS -> clearing.clearing_volumes.plus

  let get_cleared_sell_side_payout
    (from: token)
    (to: token)
    (amount: nat)
    (clearing: clearing)
    (tam: TokenAmountMap.t): TokenAmountMap.t =
    let f_sell_side_actual_volume: Rational.t = Rational.new (int clearing.prorata_equivalence.sell_side_actual_volume) in
    let f_amount = Rational.new (int amount) in
    let prorata_allocation = Rational.div f_amount f_sell_side_actual_volume in
    let f_buy_side_clearing_volume = Rational.new (int (get_clearing_volume clearing)) in
    let payout = Rational.mul prorata_allocation f_buy_side_clearing_volume in
    let payout_equiv = Rational.mul payout clearing.clearing_rate.rate in
    let remaining = Rational.sub f_amount payout_equiv in
    let fill_payout: token_amount = {
      token = to;
      amount = Math.get_rounded_number_lower_bound payout;
    } in
    if RationalUtils.gt remaining (Rational.new 1) then
      let token_rem : token_amount = {
         token = from;
         amount = Math.get_rounded_number_lower_bound remaining;
      } in
      let u_tam = TokenAmountMap.increase fill_payout tam in
      TokenAmountMap.increase token_rem u_tam
    else
      TokenAmountMap.increase fill_payout tam

  let get_cleared_buy_side_payout
    (from: token)
    (to: token)
    (amount: nat)
    (clearing:clearing)
    (tam: token_amount_map): token_amount_map =
    let f_buy_side_actual_volume = Rational.new (int clearing.prorata_equivalence.buy_side_actual_volume) in
    let f_amount = Rational.new (int amount) in
    let prorata_allocation = Rational.div f_amount f_buy_side_actual_volume in
    let f_buy_side_clearing_volume = Rational.new (int (get_clearing_volume clearing)) in
    let f_sell_side_clearing_volume = Rational.mul clearing.clearing_rate.rate f_buy_side_clearing_volume in
    let payout = Rational.mul prorata_allocation f_sell_side_clearing_volume in
    let payout_equiv = Rational.div payout clearing.clearing_rate.rate in
    let remaining = Rational.sub f_amount payout_equiv in
    let fill_payout = {
      token = to;
      amount = Math.get_rounded_number_lower_bound payout;
    } in
    if RationalUtils.gt remaining (Rational.new 0) then
      let token_rem = {
         token = from;
         amount = Math.get_rounded_number_lower_bound remaining;
      } in
      let u_tam = TokenAmountMap.increase fill_payout tam in
      TokenAmountMap.increase token_rem u_tam
    else
      TokenAmountMap.increase fill_payout tam

  let get_cleared_payout
    (ot: ordertype)
    (amt: nat)
    (clearing: clearing)
    (tam: token_amount_map): token_amount_map =
    let s = ot.side in
    let swap = clearing.clearing_rate.swap in
    match s with
    | BUY -> get_cleared_buy_side_payout swap.from.token swap.to amt clearing tam
    | SELL -> get_cleared_sell_side_payout swap.to swap.from.token amt clearing tam


  let collect_order_payout_from_clearing
    ((c, tam), (ot, amt): (clearing * token_amount_map) * (ordertype * nat)) :  (clearing * token_amount_map) =
    let u_tam: token_amount_map  = if was_in_clearing ot c then
                                     get_cleared_payout ot amt c tam
                                   else
                                     let ta: token_amount = TokenAmount.recover ot amt c in
                                     TokenAmountMap.increase ta tam
    in
    (c, u_tam)

end

type t = Types.user_batch_ordertypes

let add_order
    (holder: address)
    (batch_id: nat)
    (order : order)
    (ubots: t ) : t =
    match Big_map.find_opt holder ubots with
    | None -> let new_bots = Batch_OrderTypes.make batch_id order in
              Big_map.add holder new_bots ubots
    | Some bots -> let updated_bots = Batch_OrderTypes.add_or_update batch_id order bots in
                   Big_map.update holder (Some updated_bots) ubots

let get_clearing
   (batch: batch) : clearing option =
   match batch.status with
   | Cleared ci -> Some ci.clearing
   | _ -> None


let collect_redemptions
    ((bots, tam, bts),(batch_number,otps) : (batch_ordertypes * token_amount_map * batch_set) * (nat * ordertypes)) : (batch_ordertypes * token_amount_map * batch_set) =
    let batches = bts.batches in
    let batch_indices = bts.current_batch_indices in
    match Big_map.find_opt batch_number batches with
    | None -> (bots, tam, bts)
    | Some batch -> (let name = Utils.get_rate_name_from_pair batch.pair in
                     match Map.find_opt name batch_indices with
                     | Some _ -> (bots, tam, bts)
                     | None ->
                       (match get_clearing batch with
                        | None ->  (bots, tam, bts)
                        | Some c -> let (_c, u_tam) = Map.fold Redemption_Utils.collect_order_payout_from_clearing otps (c, tam)  in
                                   let u_bots = Map.remove batch_number bots in
                                   (u_bots,u_tam, bts)))

let collect_redemption_payouts
    (holder: address)
    (batch_set: batch_set)
    (ubots: t) :  (t * token_amount_map) =
    let empty_tam = (Map.empty : token_amount_map) in
    match Big_map.find_opt holder ubots with
    | None -> (ubots, empty_tam)
    | Some bots -> let (u_bots, u_tam, _bs) = Map.fold collect_redemptions bots (bots, empty_tam, batch_set) in
                   let updated_ubots = Big_map.update holder (Some u_bots) ubots in
                   (updated_ubots, u_tam)


let is_within_limit
  (holder: address)
  (ubots: t) : bool =
  match Big_map.find_opt holder ubots with
  | None  -> true
  | Some bots -> let outstanding_token_items = Batch_OrderTypes.count bots in
                 outstanding_token_items <= Constants.limit_of_redeemable_items



