#import "types.mligo" "CommonTypes"
#import "storage.mligo" "Storage"
#import "math.mligo" "Math"
#import "errors.mligo" "Errors"
#include "utils.mligo"
#import "constants.mligo" "Constants"
#import "userbatchordertype.mligo" "Ubots"
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
    (token_map, tal : token_amount_map * token_amount list) : token_amount_map =
    let aux (tmap,ta : token_amount_map * token_amount) : token_amount_map =
         match ta.token.address with
         | None -> tmap
         | Some addr ->  add_or_update_token_amount_in_map addr ta tmap
    in
    List.fold aux tal token_map

 let transfer_holdings (treasury_vault : address) (holder: address)  (holdings : token_amount_map) : operation list =
    let atomic_transfer (operations, (_addr,ta) : operation list * ( address * token_amount)) : operation list =
      let op: operation = handle_transfer treasury_vault holder ta in
      op :: operations
    in
    let op_list = Map.fold atomic_transfer holdings ([] : operation list)
    in
    op_list


  let order_can_be_redeemed
    (holder : address)
    (order: order) : bool = (order.redeemed = false && order.trader = holder)

  let validate_order_numbers_and_collect_orders
    (holder : address)
    (order_numbers : nat list)
    (orderbook: orderbook) : order list =
    let validate (acc,on: nat list * nat) : nat list =
      match Big_map.find_opt on orderbook with
       | None -> acc
       | Some o -> if order_can_be_redeemed holder o  then
                   on :: acc
                 else
                   acc in
    let validated_order_numbers = List.fold validate order_numbers [] in
    let collect (acc,on: order list * nat) : order list =
      match Big_map.find_opt on orderbook with
       | None -> acc
       | Some o -> o :: acc in
    List.fold collect validated_order_numbers []

end


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
