#import "types.mligo" "CommonTypes"
#import "storage.mligo" "CommonStorage"
#import "errors.mligo" "CommonErrors"

module Utils = struct
  type storage = CommonStorage.Types.t
  type treasury = CommonTypes.Types.treasury
  type token_amount = CommonTypes.Types.token_amount
  type treasury_token = CommonTypes.Types.treasury_token

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
  type transfer = transfer_from list

  (* Transfer the tokens to the appropriate address. This is based on the FA2 token standard *) 
  let transfer_token 
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation = 
      let transfer_entrypoint : transfer contract = 
        match (Tezos.get_entrypoint_opt "%transfer" token_address : transfer contract option) with 
        | None -> failwith CommonErrors.invalid_token_address
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
      | None -> failwith CommonErrors.invalid_tezos_address
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
    match Big_map.get_and_update with 
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
       
  let deposit 
    (deposit_address : address) 
    (treasury_vault : address)
    (deposited_token : token_amount) 
    (storage : storage) : storage =
      let treasury = deposit_treasury deposit_address deposited_token storage.treasury in
      let _ = handle_transfer deposit_address treasury_vault deposited_token in 
      { storage with treasury = treasury }

  let handle_redeemed_treasury_token 
    (token : token) 
    (amount : nat) 
    (treasury_vault : address) 
    (treasury_token : treasury_token) : unit = 
      match Big_map.get_and_update with 
        token
        (None : nat) 
        treasury_token
      with 
      | (None, treasury_token) -> 
        failwith CommonErrors.not_found_token
      | (Some old_token_amount, treasury_token) -> 
        if old_token_amount.amount < amount then 
          failwith CommonErrors.greater_than_owned_token
        else 
          let remaining_amount = abs (old_token_amount.amount - amount) in 
          let _ = handle_transfer treasury_vault deposit_address { token = token; amount = remaining_amount } in 
          ()
    
  (* Redeem the remaining tokens to the original storage after the end of swap process *)
  let redeem_treasury 
    (deposit_address : address) 
    (redeemed_token : token_amount) 
    (treasury_vault : address) 
    (treasury : treasury) : treasury =
      match Big_map.get_and_update
        deposit_address
        (None : treasury_token option)
        treasury
      with
      | (None, treasury) ->
        failwith CommonErrors.incorrect_address
      | (Some old_treasury_token, treasury) ->
        let _ = handle_redeemed_treasury_token redeemed_token.token redeemed_token.amount treasury_vault old_treasury_token in 
        let treasury_token = Big_map.remove redeemed_token.token old_treasury_token 
        Big_map.add deposit_address treasury_token treasury

  let redeem 
    (deposit_address : address)
    (redeem_address : address) 
    (treasury_vault : address) 
    (redeemed_token : token_amount) 
    (storage : storage) : storage =
      let _ = handle_transfer treasury_vault redeem_address redeemed_token in
      let treasury = redeem_treasury deposit_address redeemed_token treasury_vault storage.treasury in 
      { storage with treasury = treasury }
end