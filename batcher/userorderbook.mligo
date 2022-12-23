#import "types.mligo" "CommonTypes"
#import "utils.mligo" "Utils"
#import "errors.mligo" "Errors"
#import "math.mligo" "Math"
#import "../math_lib/lib/float.mligo" "Float"
#import "treasury.mligo" "Treasury"
#import "constants.mligo" "Constants"

type order = CommonTypes.Types.swap_order
type side = CommonTypes.Types.side
type tolerance = CommonTypes.Types.tolerance
type clearing = CommonTypes.Types.clearing
type exchange_rate = CommonTypes.Types.exchange_rate
type t = CommonTypes.Types.user_orderbook
type user_orders = CommonTypes.Types.user_orders

let make_new_order_map
  (order: order) : user_orders =
  Map.literal [
    (Constants.open, [ order ]);
    (Constants.redeemed, [])]

let add_open_order
  (order: order)
  (user_orders : user_orders): user_orders =
  match Map.find_opt Constants.open user_orders with
  | None -> make_new_order_map order
  | Some op_ords -> Map.update Constants.open (Some (order::op_ords)) user_orders

let clean_redeemed_orders
  (redeemed_orders: order list) : order list =
  let can_order_be_cleared (order: order) : bool  = (order.created_at + Constants.redeemed_order_removal_time < Tezos.get_now ()) in
  let clean (o, ords: order * order list) = if can_order_be_cleared o then ords else o :: ords in
  List.fold_right clean redeemed_orders []

let push_redeemed_orders
  (redeemed_orders: order list)
  (user_orders : user_orders): user_orders =
  let previously_redeemed  = Map.find_opt Constants.redeemed user_orders in
  let all_redemptions:user_orders  = match previously_redeemed with
                                     | None -> Map.add Constants.redeemed redeemed_orders user_orders
                                     | Some prev -> let cleaned = clean_redeemed_orders prev in
                                                    let joined_redemptions = List.fold_right (fun (o, ords: order * order list) -> o :: ords) redeemed_orders cleaned in
                                                    Map.update Constants.redeemed (Some joined_redemptions) user_orders
  in
  Map.update Constants.open (Some []) all_redemptions

let push_open_order
  (holder: address)
  (order: order)
  (user_orderbook : t): t =
  match Big_map.find_opt holder user_orderbook with
  | None -> let new_user_orders = make_new_order_map order in
            Big_map.add holder new_user_orders user_orderbook
  | Some ords -> let new_user_orders = add_open_order order ords in
                 Big_map.update holder (Some new_user_orders) user_orderbook

