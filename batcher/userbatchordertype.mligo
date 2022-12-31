#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"
#import "math.mligo" "Math"
#import "../math_lib/lib/float.mligo" "Float"

module Types = CommonTypes.Types


type ordertype = Types.ordertype
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


end

  (*
  type ordertype = {
     side: side;
     tolerance: tolerance;
  }
  type ordertypes = (ordertype, nat) map
  type batch_ordertypes = (nat,  ordertypes) map
  type user_batch_ordertypes = (address, batch_ordertypes) big_map *)

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
    (order:order)
    (clearing: clearing) : bool =
    let order_tolerance = order.tolerance in
    let order_side = order.side in
    let clearing_tolerance = clearing.clearing_tolerance in
    match order_side with
    | BUY -> was_in_clearing_for_buy clearing_tolerance order_tolerance
    | SELL -> was_in_clearing_for_sell clearing_tolerance order_tolerance

  let get_clearing
    (batch: batch) : clearing option =
    match batch.status with
    | Cleared { at = _ ; clearing = c; rate = _ } -> Some c
    | _ -> None


  let get_clearing_volume
    (clearing:clearing) : nat =
    match clearing.clearing_tolerance with
    | MINUS -> clearing.clearing_volumes.minus
    | EXACT -> clearing.clearing_volumes.exact
    | PLUS -> clearing.clearing_volumes.plus

  let get_cleared_sell_side_payout
    (swap:swap)
    (clearing:clearing) : token_amount list =
    let f_sell_side_actual_volume = Float.new (int clearing.prorata_equivalence.sell_side_actual_volume) 0 in
    let f_amount = Float.new (int swap.from.amount) 0 in
    let prorata_allocation = Float.div f_amount f_sell_side_actual_volume in
    let f_buy_side_clearing_volume = Float.new (int (get_clearing_volume clearing)) 0 in
    let payout = Float.mul prorata_allocation f_buy_side_clearing_volume in
    let payout_equiv = Float.mul payout clearing.clearing_rate.rate in
    let remaining = Float.sub f_amount payout_equiv in
    let fill_payout: token_amount = {
      token = swap.to;
      amount = Math.get_rounded_number payout;
    } in
    if Float.gt remaining (Float.new 0 0) then
      let token_rem : token_amount = {
         token = swap.from.token;
         amount = Math.get_rounded_number remaining;
      } in
      [ fill_payout; token_rem ]
    else
      [ fill_payout ]

  let get_cleared_buy_side_payout
    (swap:swap)
    (clearing:clearing) : token_amount list =
    let f_buy_side_actual_volume = Float.new (int clearing.prorata_equivalence.buy_side_actual_volume) 0 in
    let f_amount = Float.new (int swap.from.amount) 0 in
    let prorata_allocation = Float.div f_amount f_buy_side_actual_volume in
    let f_buy_side_clearing_volume = Float.new (int (get_clearing_volume clearing)) 0 in
    let f_sell_side_clearing_volume = Float.mul clearing.clearing_rate.rate f_buy_side_clearing_volume in
    let payout = Float.mul prorata_allocation f_sell_side_clearing_volume in
    let payout_equiv = Float.div payout clearing.clearing_rate.rate in
    let remaining = Float.sub f_amount payout_equiv in
    let fill_payout = {
      token = swap.to;
      amount = Math.get_rounded_number payout;
    } in
    if Float.gt remaining (Float.new 0 0) then
      let token_rem = {
         token = swap.from.token;
         amount = Math.get_rounded_number remaining;
      } in
      [ fill_payout; token_rem ]
    else
      [ fill_payout ]

  let get_cleared_payout
    (order: order)
    (clearing: clearing) : token_amount list =
    match order.side with
    | BUY -> get_cleared_buy_side_payout order.swap clearing
    | SELL -> get_cleared_buy_side_payout order.swap clearing

  let collect_order_payout_from_clearing
    (order, clearing: order * clearing option) :  token_amount list =
    match clearing with
    | None -> [ order.swap.from ]
    | Some c -> if was_in_clearing order c then
                  let cleared_token_amount = get_cleared_payout order c in
                  cleared_token_amount
                else
                  [ order.swap.from ]
end

type t = Types.user_batch_ordertypes

let add_order
    (holder: address)
    (batch_id: nat)
    (order : order)
    (ubot : t ) : t =
    match Big_map.find_opt holder ubot with
    | None -> let new_bots = Batch_OrderTypes.make batch_id order in
              Big_map.add holder new_bots ubot
    | Some bots -> let updated_bots = Batch_OrderTypes.add_or_update batch_id order bots in
                   Big_map.update holder (Some updated_bots) ubot

let collect_redemption_payouts
    (holder: address)
    (batch_set: batch_set)
    (ubot: t) :  (t * token_amount_map) =
    match Big_map.find_opt holder ubot with
    | None -> (ubot, (Map.empty : token_amount_map))
    | Some _bot -> (ubot, (Map.empty : token_amount_map))






