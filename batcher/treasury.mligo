#import "types.mligo" "Types"
#import "storage.mligo" "Storage"
#import "errors.mligo" "Errors"
#include "utils.mligo"
#import "constants.mligo" "Constants"
#import "../math_lib/lib/float.mligo" "Float"

type storage = Storage.Types.t
type token_amount = Types.Types.token_amount
type token = Types.Types.token
type token_holding = Types.Types.token_holding
type pair = Types.Types.token * Types.Types.token
type batch = Types.Types.batch
type batch_set = Types.Types.batch_set
type order = Types.Types.swap_order
type clearing = Types.Types.clearing
type tolerance = Types.Types.tolerance
type user_orders = Types.Types.user_orders
type token_amount_option = Types.Types.token_amount option


module Utils = struct
  type adjustment = INCREASE | DECREASE
  type order_list = order list
  type token_amount_map = (address, token_amount) map


 type atomic_trans =
    [@layout:comb] {
    to_  : address;
    token_id : nat;
    amount : nat;
  }

  type transfer_from = {
    from_ : address;
    tx : atomic_trans list
  }

  (* Transferred format for tokens in FA2 standard *)
  type fa2_transfer = transfer_from list

  (* Transferred format for tokens in FA12 standard *)
  type fa12_transfer =
    [@layout:comb] {
    [@annot:from] address_from : address;
    [@annot:to] address_to : address;
    value : nat
  }



  let transfer_fa12_token
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation =
      let transfer_entrypoint : fa12_transfer contract =
        match (Tezos.get_entrypoint_opt "%transfer" token_address : fa12_transfer contract option) with
        | None -> failwith Errors.invalid_token_address
        | Some transfer_entrypoint -> transfer_entrypoint
      in
      let transfer : fa12_transfer = {
        address_from = sender;
        address_to = receiver;
        value = token_amount
      } in
      Tezos.transaction transfer 0tez transfer_entrypoint

  let transfer_fa2_token
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation =
      let transfer_entrypoint : fa2_transfer contract =
        match (Tezos.get_entrypoint_opt "%transfer" token_address : fa2_transfer contract option) with
        | None -> failwith Errors.invalid_token_address
        | Some transfer_entrypoint -> transfer_entrypoint
      in
      let transfer : fa2_transfer = [
        {
          from_ = sender;
          tx = [
            {
              to_ = receiver;
              token_id = 0n;
              amount = token_amount
            }
          ]
        }
      ] in
      Tezos.transaction transfer 0tez transfer_entrypoint


  (* Transfer the tokens to the appropriate address. This is based on the FA12 and FA2 token standard *)
  let transfer_token (sender : address) (receiver : address) (token_address : address) (token_amount : token_amount) : operation =
    match token_amount.token.standard with
    | Some standard ->
      if standard = Constants.fa12_token then
        transfer_fa12_token sender receiver token_address token_amount.amount
      else if standard = Constants.fa2_token then
        transfer_fa2_token sender receiver token_address token_amount.amount
      else
        failwith Errors.not_found_token_standard
    | None ->
      failwith Errors.not_found_token_standard

  (* Transfer the XTZ to the appropriate address *)
  let transfer_xtz (receiver : address) (amount : tez) : operation =
    let received_contract : unit contract =
      match (Tezos.get_contract_opt receiver : unit contract option) with
      | None -> failwith Errors.invalid_tezos_address
      | Some address -> address in
    Tezos.transaction () amount received_contract

  let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
    match received_token.token.address with
    | None ->
      let xtz_amount = received_token.amount * 1tez in
      transfer_xtz receiver xtz_amount
    | Some token_address ->
      transfer_token sender receiver token_address received_token



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
    (clearing:clearing) = nat =
    match clearing.clearing_tolerance with
    | MINUS -> clearing.clearing_volumes.minus
    | EXACT -> clearing.clearing_volumes.exact
    | PLUS -> clearing.clearing_volumes.plus

  let get_cleared_sell_side_payout
    (swap:swap)
    (clearing:clearing) : token_amount list =
    let f_sell_side_actual_volume = Float.new clearing.prorata_equivalence.sell_side_actual_volume 0 in
    let f_amount = Float.new swap.from.amount 0 in
    let prorata_allocation = Float.div f_amount f_sell_side_actual_volume in
    let f_buy_side_clearing_volume = Float.new (get_clearing_volume clearing) 0 in
    let payout = Float.mul prorata_allocation buy_side_clearing_volume in
    let payout_equiv = Float.mul clearing.clearing_rate payout in
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
      [ fill_payout, token_rem ]
    else
      [ fill_payout ]

  let get_cleared_buy_side_payout
    (swap:swap)
    (clearing:clearing) : token_amount list =
    let f_buy_side_actual_volume = Float.new clearing.prorata_equivalence.buy_side_actual_volume 0 in
    let f_amount = Float.new swap.from.amount 0 in
    let prorata_allocation = Float.div f_amount f_buy_side_actual_volume in
    let f_buy_side_clearing_volume = Float.new (get_clearing_volume clearing) 0 in
    let sell_side_clearing_volume = Float.mul clearing.clearing_rate f_amount f_buy_side_clearing_volume in
    let payout = Float.mul prorata_allocation sell_side_clearing_volume in
    let payout_equiv = Float.div clearing.clearing_rate payout in
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
      [ fill_payout, token_rem ]
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
    | None -> order.swap.from
    | Some c -> if was_in_clearing order c then
                  let cleared_token_amount = get_cleared_payout order c in
                  cleared_token_amount
                else
                  [ order.swap.from ]

  let redeemed_order
    (order: order) = { order with redeemed = true }


  let add_or_update_token_amount_in_map
    (addr: address)
    (ta: token_amount)
    (tam: token_amount_map) : token_amount_map =
    match (Map.find_opt addr tam) with
    | None ->  Map.add addr ta tam
    | Some t -> let new_amount = ta.amount + t.amount in
                let new_token_amount = { t with amount = new_amount } in
                Map.update addr (Some new_token_amount) tam


  let collate_token_amounts
    (token_map, ta : token_amount_map * token_amount) : token_amount_map =
    match ta.token.address with
    | None -> (Map.empty : token_amount_map)
    | Some addr ->  add_or_update_token_amount_in_map addr ta token_map


  let collect_order_payouts
    (user_orders: user_orders)
    (batch_set: batch_set)
    (storage : storage) : operation list * storage =
    let open_orders : (order list) option = Map.find_opt Constants.open user_orders in
    let (redeemed_orders, payout_token_amount_options) = match open_orders with
                                                         | None -> (([]: order list), ([]: token_amount_option list))
                                                         | Some ords -> let match_order_to_batch
                                                                        (order: order) : (order * clearing option) =
                                                                           match Big_map.find_opt order.batch_number batch_set.batches with
                                                                           | None -> (order, None)
                                                                           | Some b -> (order, get_clearing b)
                                                                       in
                                                                       let orders_and_clearing: (order * clearing option) list = List.map match_order_to_batch ords in
                                                                       let redeemed_orders  = List.map redeemed_order ords in
                                                                       let payouts: token_amount list = List.map collect_order_payout_from_clearing orders_and_clearing in
                                                                       (([]: order list), ([]: token_amount_option list))
       in
       let operations = ([]: operation list)  in
       (operations,  storage)


  let redeem_holdings
    (holder : address)
    (treasury_vault : address)
    (storage : storage) : operation list * storage =
       let user_orders: user_orders option = Big_map.find_opt holder storage.user_orderbook in
       let batch_set = storage.batch_set in
       let empty_ops = ([]: operation list)  in
       let redeemed_ops_and_storage =  match user_orders with
                                       | None ->  (empty_ops, storage)
                                       | Some uords -> collect_order_payouts uords batch_set storage
       in
       (* let operations = transfer_holdings treasury_vault holder holdings in *)
       let operations = ([]: operation list)  in
       (operations,  storage)
end


let get_treasury_vault () : address = Tezos.get_self_address ()





let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (storage : storage) : operation * storage =
      let (op, update_storage) = match Types.Utils.get_current_batch storage.batch_set with
                                 | None -> (failwith Errors.no_current_batch_available : operation * storage)
                                 | Some _batch -> let treasury_vault = get_treasury_vault () in
                                                  let transfer_operation = Utils.handle_transfer deposit_address treasury_vault deposited_token in
                                                  (transfer_operation, storage )
      in
      (op, update_storage)

let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let (ops, updated_storage) = Utils.redeem_holdings redeem_address treasury_vault storage in
      (ops, updated_storage)
