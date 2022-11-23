#import "types.mligo" "Types"
#import "storage.mligo" "Storage"
#import "errors.mligo" "Errors"
#include "utils.mligo"
#import "constants.mligo" "Constants"

type storage = Storage.Types.t
type treasury = Types.Types.treasury
type token_amount = Types.Types.token_amount
type token = Types.Types.token
type treasury_holding = Types.Types.treasury_holding
type token_holding = Types.Types.token_holding
type pair = Types.Types.token * Types.Types.token
type batch = Types.Types.batch
type batch_set = Types.Types.batch_set

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

  (* Check that the a treasury holding holds the token required for the swap *)
  let check_treasury_holding
    (holding : token_holding )
    (th : treasury_holding) : token_holding =
    let token_name = Types.Utils.get_token_name_from_token_holding holding in
    match (Map.find_opt (token_name) th) with
    | Some (tkh) -> let _ = check_token_holding_amount holding tkh in
                    tkh
    | None -> (failwith Errors.insufficient_token_holding : token_holding)

  (* Check that the treasury contains a sufficient holding for the swap being proposed *)
  let has_sufficient_holding
    (holding : token_holding)
    (treasury : treasury ): treasury_holding =
    match Big_map.find_opt holding.holder treasury with
     | Some th ->  let _ = check_treasury_holding holding th in
                   th
     | None -> (failwith Errors.no_treasury_holding_for_address : treasury_holding)

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

  (* asserts that the holdings held in a treasury holding match the holder address *)
  let assert_holdings_are_coherent
    (holder: address)
    (treasury_holding : treasury_holding) : unit =
    let is_coherent = fun (_s,th : string * token_holding) -> assert (th.holder = holder) in
    Map.iter is_coherent treasury_holding

  (* Adjusts the token holding within the treasury.   *)
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

  (* Find the associated treasury holding and adjusts the appropriate token holding *)
  let adjust_treasury_holding
    (token_name : string)
    (assigned_token_holder : address)
    (adjustment : adjustment)
    (token_holding : token_holding)
    (treasury_holding : treasury_holding) : treasury_holding =
    let existing_token_holding_opt = Map.find_opt token_name treasury_holding in
    match adjustment with
    | DECREASE -> (match existing_token_holding_opt with
                   | None -> (failwith Errors.insufficient_token_holding_for_decrease : treasury_holding)
                   | Some (th) -> let new_holding = adjust_token_holding th DECREASE token_holding in
                                  Map.update (token_name) (Some(new_holding)) treasury_holding)
    | INCREASE -> (match existing_token_holding_opt with
                   | None -> let new_holding = Types.Utils.assign_new_holder_to_token_holding assigned_token_holder token_holding in
                             Map.add token_name new_holding treasury_holding
                   | Some (th) -> let new_holding = adjust_token_holding th INCREASE token_holding in
                                  Map.update (token_name) (Some(new_holding)) (treasury_holding))

  (*
  Swaps the tokens by first reducing the token holding for each user of the appropriate token
  and then increasing the holding of the opposing token and assining the new holder.
  *)
  let atomic_swap
    (this_token_holding : token_holding)
    (this_treasury_holding : treasury_holding)
    (with_that_token_holding : token_holding)
    (with_that_treasury_holding : treasury_holding)
    (treasury : treasury) : treasury =
    let this_holder_address = this_token_holding.holder in
    let with_that_holder_address = with_that_token_holding.holder in
    let this_token_name = Types.Utils.get_token_name_from_token_holding this_token_holding in
    let with_that_token_name = Types.Utils.get_token_name_from_token_holding with_that_token_holding in
    let this_h = adjust_treasury_holding this_token_name this_holder_address DECREASE this_token_holding this_treasury_holding in
    let that_h = adjust_treasury_holding with_that_token_name with_that_holder_address DECREASE with_that_token_holding with_that_treasury_holding in
    let this_h = adjust_treasury_holding with_that_token_name this_holder_address INCREASE with_that_token_holding this_h in
    let that_h = adjust_treasury_holding this_token_name with_that_holder_address INCREASE this_token_holding that_h in
    let _ = assert_holdings_are_coherent this_holder_address this_h in
    let _ = assert_holdings_are_coherent with_that_holder_address that_h in
    let treasury = Big_map.update (this_holder_address) (Some(this_h)) treasury in
    let treasury = Big_map.update (with_that_holder_address) (Some(that_h)) treasury in
    treasury

  let deposit_into_treasury_holding
    (address : address)
    (token_name : string)
    (token_holding : token_holding)
    (treasury : treasury) : treasury_holding =
    match Big_map.find_opt address treasury with
    | None -> Map.literal [ (token_name, token_holding )]
    | Some (treasury_holding) ->  (match Map.find_opt token_name treasury_holding with
                                   | None ->  Map.add (token_name) (token_holding) (treasury_holding)
                                   | Some (oth) -> let new_token_holding = adjust_token_holding oth INCREASE token_holding in
                                                   Map.update (token_name) (Some(new_token_holding)) (treasury_holding))

  (* Deposit tokens into storage *)
  let deposit_treasury (address : address) (received_token : token_amount) (treasury : treasury) : treasury =
    let token_name = Types.Utils.get_token_name_from_token_amount received_token in
    let token_holding = Types.Utils.token_amount_to_token_holding address received_token false in
    let new_treasury_holding = deposit_into_treasury_holding address token_name token_holding treasury in
    let _ = assert_holdings_are_coherent address new_treasury_holding in
    Big_map.update (address) (Some(new_treasury_holding)) treasury

  let accumulate_holdings_from_single_batch
    (holder : address)
    (batch : batch)
    (redeemed_holding : treasury_holding) : (treasury_holding * batch) =
      match batch.status with
      | Cleared _ -> (
        match Big_map.find_opt holder batch.treasury with
        | None -> (redeemed_holding, batch)
        | Some th ->
          let accumulate (redeemed_holding, (token_name, token_holding) : treasury_holding * (string * token_holding)) : treasury_holding =
            match Map.find_opt token_name redeemed_holding with
            | None -> Map.add token_name token_holding redeemed_holding
            | Some old_token_holding ->
              let updated_amount = old_token_holding.token_amount.amount + token_holding.token_amount.amount in
              let updated_token_amount = { token_holding.token_amount with amount = updated_amount } in
              let updated_token_holding = { token_holding with token_amount = updated_token_amount } in
              Map.update token_name (Some updated_token_holding) redeemed_holding
          in
          let redeemed_holding = Map.fold accumulate th redeemed_holding in
          let updated_treasury = Big_map.remove holder batch.treasury in
          let updated_batch = { batch with treasury = updated_treasury } in
          (redeemed_holding, updated_batch))
      | Open _ -> (redeemed_holding, batch)
      | Closed _  -> (redeemed_holding, batch)

  let get_updated_previous_batches (holder : address) (previous_batches : batch list) : batch list =
    let filter (batch : batch) : batch =
      let (_, updated_batch) = accumulate_holdings_from_single_batch holder batch (Map.empty : treasury_holding) in
      updated_batch
    in
    List.map filter previous_batches

  let accumulate_holdings_previous_batches (holder : address) (previous_batches : batch list) : treasury_holding =
    let filter (redeemed_holding, batch : treasury_holding * batch) : treasury_holding =
      let (redeemed_holding, _) = accumulate_holdings_from_single_batch holder batch redeemed_holding in
      redeemed_holding
    in
    List.fold filter previous_batches (Map.empty : treasury_holding)

  let transfer_holdings (treasury_vault : address) (redeemed_holding : treasury_holding) : operation list =
    let atomic_transfer (operations, (_, token_holding) : operation list * (string * token_holding)) : operation list =
      let op = handle_transfer treasury_vault token_holding.holder token_holding.token_amount in
      op :: operations
    in
    Map.fold atomic_transfer redeemed_holding ([] : operation list)

  let redeem_holdings_from_batches
    (holder : address)
    (treasury_vault : address)
    (batches : batch_set) : operation list * batch_set =
      let updated_previous_batches = get_updated_previous_batches holder batches.previous in
      let redeemed_holding = accumulate_holdings_previous_batches holder batches.previous in
      let operations = transfer_holdings treasury_vault redeemed_holding in
      (operations, { batches with previous = updated_previous_batches })
end

let get_treasury_vault () : address = Tezos.get_self_address ()

let empty : treasury = Big_map.empty

let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (storage : storage) : operation * storage =
      let batches = storage.batches in
      let (op, current_batch)  = (match batches.current with
                                     | None -> (* We should never get here without a current batch *)
                                               (failwith Errors.no_current_batch_available : operation * batch)
                                     | Some (cb) -> let updated_current_batch_treasury : treasury = Utils.deposit_treasury deposit_address deposited_token cb.treasury in
                                                    let treasury_vault = get_treasury_vault () in
                                                    let transfer_operation = Utils.handle_transfer deposit_address treasury_vault deposited_token in
                                                    (transfer_operation, { cb with treasury = updated_current_batch_treasury })) in
      let updated_batches = { batches with current = Some(current_batch) } in
      (op, { storage with batches = updated_batches })

let redeem
    (redeem_address : address)
    (storage : storage) : operation list * storage =
      let treasury_vault = get_treasury_vault () in
      let (ops, updated_batches) = Utils.redeem_holdings_from_batches redeem_address treasury_vault storage.batches in
      (ops, { storage with batches = updated_batches })

let swap
    (this : token_holding)
    (with_that : token_holding)
    (treasury : treasury) : treasury =
    let this_holding = Utils.has_sufficient_holding this treasury in
    let that_holding = Utils.has_sufficient_holding with_that treasury in
    Utils.atomic_swap this this_holding with_that that_holding treasury
