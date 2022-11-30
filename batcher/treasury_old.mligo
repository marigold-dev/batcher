#import "types.mligo" "Types"
#import "storage.mligo" "Storage"
#import "errors.mligo" "Errors"
#include "utils.mligo"
#import "constants.mligo" "Constants"

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

module Utils = struct
  type adjustment = INCREASE | DECREASE

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

  (* Check that the token holding amount is greater or equal to the token amount being swapped *)
  let check_token_holding_amount
    (holding : token_holding)
    (tkh: token_holding) : token_holding =
    if (tkh.token_amount.amount >= holding.token_amount.amount) then tkh else (failwith Errors.insufficient_token_holding : token_holding)



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


  (* Adjusts the token holding.  *)
  let adjust_token_holding
    (th : token_holding)
    (adjustment : adjustment)
    (adjustment_holding : token_holding) : token_holding =
      let original_token_amount = th.token_amount in
      let adjustment_token_amount = Types.Utils.check_token_equality original_token_amount adjustment_holding.token_amount in
      let original_balance = original_token_amount.amount in
      let adjustment_balance = adjustment_token_amount.amount in
      let new_balance = (match adjustment with
                         | INCREASE -> original_balance + adjustment_balance
                         | DECREASE -> abs (original_balance - adjustment_balance)
                         ) in
      let new_token_amount = { original_token_amount with amount = new_balance  } in
      { th with token_amount = new_token_amount }


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


  let accumulate_holdings_from_single_batch
    (holder : address)
    (batch : batch)
    (redeemed_holdings : token_holding list) : (token_holding list * batch) =
      match batch.status with
      | Cleared _ ->  (redeemed_holdings, batch)
      | Open _ -> (redeemed_holdings, batch)
      | Closed _  -> (redeemed_holdings, batch)


 (*
 let transfer_holdings (treasury_vault : address) (holder: address)  (holdings : token_holding list) : operation list =
    let atomic_transfer (operations, th : operation list * token_holding) : operation list =
      let op: operation = handle_transfer treasury_vault holder th.token_amount in
      op :: operations
    in
    let op_list = Map.fold atomic_transfer holdings ([] : operation list)
    in
    op_list
*)

  let redeem_holdings_from_batches
    (holder : address)
    (treasury_vault : address)
    (batches : batch_set) : operation list * batch_set =
      (* let operations = transfer_holdings treasury_vault holder holdings in *)
      let operations = ([]: operation list)  in
      (operations,  batches )
end


let get_treasury_vault () : address = Tezos.get_self_address ()

let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (storage : storage) : operation * storage =
      let (op, update_storage) =  if  storage.batch_set.current_batch_number = 0n  then
                                    (failwith Errors.no_current_batch_available : operation * storage)
                                  else
                                   let treasury_vault = get_treasury_vault () in
                                   let transfer_operation = Utils.handle_transfer deposit_address treasury_vault deposited_token in
                                   (transfer_operation, storage )
      in
      (op, update_storage)

let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let (ops, updated_batches) = Utils.redeem_holdings_from_batches redeem_address treasury_vault storage.batch_set in
      let btchs : batch_set = updated_batches in
      (ops, { storage with batch_set = btchs })
