#import "types.mligo" "CommonTypes"
#import "constants.mligo" "Constants"
#import "errors.mligo" "Errors"

module Types = CommonTypes.Types


type t = Types.user_batch_ordertypes
type ordertype = Types.ordertype
type ordertypes = Types.ordertypes
type batch_ordertypes = Types.batch_ordertypes
type order = Types.swap_order


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


