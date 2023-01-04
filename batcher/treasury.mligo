#import "types.mligo" "CommonTypes"
#import "storage.mligo" "Storage"
#import "math.mligo" "Math"
#import "errors.mligo" "Errors"
#include "utils.mligo"
#import "constants.mligo" "Constants"
#import "userbatchordertypes.mligo" "Ubots"
#import "../math_lib/lib/float.mligo" "Float"

module Types = CommonTypes.Types
type storage = Storage.Types.t
type token_amount = Types.token_amount
type token = Types.token
type token_holding = Types.token_holding
type pair = Types.token * Types.token
type batch = Types.batch
type batch_set = Types.batch_set
type order = Types.swap_order
type orderbook = Types.orderbook
type swap = Types.swap
type clearing = Types.clearing
type tolerance = Types.tolerance
type token_amount_option = Types.token_amount option
type token_amount_map = Types.token_amount_map
type user_batch_ordertypes = Types.user_batch_ordertypes


module Utils = struct
  type adjustment = INCREASE | DECREASE
  type order_list = order list


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


  let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
    match received_token.token.address with
    | None -> failwith Errors.xtz_not_currently_supported
    | Some token_address ->
        transfer_token sender receiver token_address received_token


 let transfer_holdings (treasury_vault : address) (holder: address)  (holdings : token_amount_map) : operation list =
    let atomic_transfer (operations, (_token_name,ta) : operation list * ( string * token_amount)) : operation list =
      let op: operation = handle_transfer treasury_vault holder ta in
      op :: operations
    in
    let op_list = Map.fold atomic_transfer holdings ([] : operation list)
    in
    op_list


  let collect_order_payouts
    (holder : address)
    (treasury_vault : address)
    (user_orders: user_orders)
    (batch_set: batch_set)
    (storage : storage) : operation list * storage =
    let open_orders : (order list) option = Map.find_opt Constants.open user_orders in
    let (redeemed_orders, payout_token_map) = match open_orders with
                                                         | None -> (([]: order list), (Map.empty: token_amount_map))
                                                         | Some ords -> let match_order_to_batch
                                                                        (order: order) : (order * clearing option) =
                                                                           match Big_map.find_opt order.batch_number batch_set.batches with
                                                                           | None -> (order, None)
                                                                           | Some b -> (order, get_clearing b)
                                                                       in
                                                                       let orders_and_clearing: (order * clearing option) list = List.map match_order_to_batch ords in
                                                                       let redeemed_orders  = List.map redeemed_order ords in
                                                                       let payouts: (token_amount list) list = List.map collect_order_payout_from_clearing orders_and_clearing in
                                                                       let collated_payouts = List.fold collate_token_amounts payouts Map.empty in
                                                                       (redeemed_orders,collated_payouts)
    in
    let updated_user_orders = push_redeemed_orders redeemed_orders user_orders in
    let updated_user_orderbook = Big_map.update holder (Some updated_user_orders) storage.user_orderbook in
    let operations = transfer_holdings treasury_vault holder payout_token_map in
    (operations,  { storage with user_orderbook = updated_user_orderbook })


  let redeem_holdings
    (holder : address)
    (treasury_vault : address)
    (storage : storage) : operation list * storage =
       let user_orders: user_orders option = Big_map.find_opt holder storage.user_orderbook in
       let batch_set = storage.batch_set in
       let empty_ops = ([]: operation list)  in
       let redeemed_ops_and_storage =  match user_orders with
                                       | None ->  (empty_ops, storage)
                                       | Some uords -> collect_order_payouts holder treasury_vault uords batch_set storage
       in
       redeemed_ops_and_storage


let get_treasury_vault () : address = Tezos.get_self_address ()


let deposit
    (deposit_address : address)
    (deposited_token : token_amount): operation  =
      let treasury_vault = get_treasury_vault () in
      Utils.handle_transfer deposit_address treasury_vault deposited_token


let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let (updated_ubots, payout_token_map) = Ubots.collect_redemption_payouts redeem_address storage.batch_set storage.user_batch_ordertypes in
      let operations = Utils.transfer_holdings treasury_vault redeem_address payout_token_map in
      let updated_storage = { storage with user_batch_ordertypes = updated_ubots; } in
      (operations, updated_storage)
