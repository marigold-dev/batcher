#import "types.mligo" "Types"
#import "storage.mligo" "Storage"
#import "errors.mligo" "Errors"

module Utils = struct
  type storage = Storage.Types.t
  type treasury = Types.Types.treasury
  type token_amount = Types.Types.token_amount
  type token = Types.Types.token
  type treasury_holding = Types.Types.treasury_holding
  type treasury_token = Types.Types.treasury_token
  type adjustment = INCREASE | DECREASE

  type transfer_from = {
    from_ : address;
    tx : atomic_trans list
  }

  (* Transferred format for tokens in FA2 standard *)
  type transfer = transfer_from list

  let treasury_vault : address = Tezos.self_address

  (* Transfer the tokens to the appropriate address. This is based on the FA2 token standard *)
  let transfer_token
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation =
      let transfer_entrypoint : transfer contract =
        match (Tezos.get_entrypoint_opt "%transfer" token_address : transfer contract option) with
        | None -> failwith Errors.invalid_token_address
        | Some transfer_entrypoint -> transfer_entrypoint
      in
      let transfer : transfer = [
        {
          from_ = sender;
          tx = [
            {
              to_ = receiver;
              token_id = 0n; // Need more discussion to decide to whether have token_id parameter or not
              amount = token_amount
            }
          ]
        }
      ] in
      Tezos.transaction transfer 0tez transfer_entrypoint

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
      transfer_token sender receiver token_address received_token.amount

  let handle_deposited_treasury_token (token : token) (amount : nat) (treasury_token : treasury_token) : treasury_token =
    match Big_map.get_and_update
      token
      (None : nat)
      treasury_token
    with
    | (None, treasury_token) ->
      Big_map.add token amount treasury_token
    | (Some old_token_amount, treasury_token) ->
      let updated_amount = old_token_amount.amount + amount in
      Big_map.add token updated_amount treasury_token

  (* Deposit tokens into storage *)
  let deposit_treasury (address : address) (received_token : token_amount) (treasury : treasury) : treasury =
    match Big_map.get_and_update
      address
      (None : treasury_token option)
      treasury
    with
    | (None, treasury) ->
      Big_map.add address received_token treasury
    | (Some old_treasury_token, treasury) ->
        let treasury_token = handle_deposited_treasury_token received_token.token received_token.amount old_treasury_token in
        Big_map.add address treasury_token treasury


  let handle_redeemed_treasury_token
    (token : token)
    (amount : nat)
    (treasury_token : treasury_token) : unit =
      match Big_map.get_and_update
        token
        (None : nat)
        treasury_token
      with
      | (None, treasury_token) ->
        failwith Errors.not_found_token
      | (Some old_token_amount, treasury_token) ->
        if old_token_amount.amount < amount then
          failwith Errors.greater_than_owned_token
        else
          let remaining_amount = abs (old_token_amount.amount - amount) in
          let _ = handle_transfer treasury_vault deposit_address { token = token; amount = remaining_amount } in
          ()

  (* Redeem the remaining tokens to the original storage after the end of swap process *)
  let redeem_treasury
    (deposit_address : address)
    (redeemed_token : token_amount)
    (treasury : treasury) : treasury =
      match Big_map.get_and_update
        deposit_address
        (None : treasury_token option)
        treasury
      with
      | (None, treasury) ->
        failwith Errors.incorrect_address
      | (Some old_treasury_token, treasury) ->
        let _ = handle_redeemed_treasury_token redeemed_token.token redeemed_token.amount treasury_vault old_treasury_token in
        let treasury_token = Big_map.remove redeemed_token.token old_treasury_token in
        Big_map.add deposit_address treasury_token treasury

  let deposit
    (deposit_address : address)
    (deposited_token : token_amount)
    (storage : storage) : storage =
      let treasury = deposit_treasury deposit_address deposited_token storage.treasury in
      let _ = handle_transfer deposit_address treasury_vault deposited_token in
      { storage with treasury = treasury }

  let redeem
    (deposit_address : address)
    (redeem_address : address)
    (redeemed_token : token_amount)
    (storage : storage) : storage =
      let _ = handle_transfer treasury_vault redeem_address redeemed_token in
      let treasury = redeem_treasury deposit_address redeemed_token treasury_vault storage.treasury in
      { storage with treasury = treasury }


  let check_token_holding_amount
    (tkh: token_holding) : token_holding = if (tkh.amount >= holding.amount) then tkh else (failwith Errors.insufficient_token_holding : token_holding)

  let check_treasury_holding
    (name : string)
    (th : treasury_holding) : token_holding =
    match (Map.find_opt (th.token_amount.token.name) th) with
    | Some (tkh) -> check_token_holding_amount tkh
    | None -> (failwith Errors.insufficient_token_holding : token_holding)

  let has_sufficient_holding
    (holding : token_holding)
    (treasury : treasury ): token_holding =
    match Big_map.find_opt holding.address treasury with
     | Some th ->  check_treasury_holding
     | None -> (failwith Errors.no_treasury_holding_for_address : token_holding)

  let adjust_token_holding
    (th : token_holding)
    (adjustment : adjustment)
    (adjustment_holding : token_holding) : token_holding =
      let original_token_amount = th.token_amount in
      let adjustment_token_amount = Types.Utils.check_token_equality original_token_amount adjustment_holding in
      let original_balance = original_token_amount.amount in
      let adjustment_balance = adjustment_token_amount.amount in
      let new_balance = (match adjustment with
                         | INCREASE -> original_balance + adjustment_balance
                         | DECREASE -> original_balance - adjustment_balance
                         ) in
      let new_token_amount = { original_amount with amount = new_balance  } in
      { original with token_amount = new_token_amount }

  let adjust_treasury_holding
    (holder : address)
    (adjustment : adjustment)
    (token_holding : token_holding)
    (treasury_holding : treasury_holding) : treasury_holding =
    let token_name = Types.Utils.get_token_name_from_token_holding token_holding in
    let existing_token_holding_opt = Map.find_opt token_name treasury_holding in
    match adjustment with
    | DECREASE -> (match existing_token_holding_opt with
                   | None -> (failwith Errors.insufficient_token_holding_for_decrease : treasury_holding)
                   | Some (th) -> let new_holding = adjust_token_holding th DECREASE token_holding in
                                 Map.update token_name Some(new_holding) treasury_holding)
    | INCREASE -> (match existing_token_holding_opt with
                   | None -> let new_holding = Types.Utils.assign_new_holder_to_token_holding token_holding in
                             Map.add token_name Some(new_holding) treasury_holding
                   | Some -> let new_holding = adjust_token_holding th INCREASE token_holding in
                             Map.update token_name Some(new_holding) treasury_holding)

  let atomic_swap
    (this_token_holding : token_holding)
    (this_treasury_holding : treasury_holding)
    (with_that_token_holding : token_holding)
    (with_that_treasury_holding : treasury_holding)
    (treasury : treasury) : treasury option =
    let this_h = adjust_treasury_holding DECREASE this_token_holding this_treasury_holding in
    let that_h = adjust_treasury_holding DECREASE with_that_token_holding with_that_treasury_holding in
    let this_h = adjust_treasury_holding INCREASE with_that_token_holding this_treasury_holding in
    let that_h = adjust_treasury_holding INCREASE this_token_holding with_that_treasury_holding in
    let t = Big_map.update this_token_holding.holder Some(this_h) treasury in
    let t = Big_map.update with_that_token_holding.holder Some(that_h) treasury in
    treasury


  let swap
    (this : token_holding)
    (with_that : token_holding)
    (treasury : treasury) : treasury =
    let this_holding = has_sufficient_holding this treasury in
    let that_holding = has_sufficient_holding with_that treasury in
    match atomic_swap this_holding that_holding treasury with
    | Some (t) -> t
    | None -> treasury

end
