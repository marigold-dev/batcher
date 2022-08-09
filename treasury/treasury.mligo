#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "errors.mligo" "TreasuryErrors"

module Utils = struct
  type storage = CommonStorage.Types.t
  type treasury = CommonStorage.Types.treasury
  type token_amount = CommonTypes.Types.token_amount

  (* Transferred format for tokens in FA12 standard *)
  type transfer_data = {
    [@layout:comb]
    from : address;
    [@annot:to] to_ : address;
    value : nat;
  }

  (* Transfer the tokens to the appropriate address. This is based on the FA 1.2 token standard *) 
  let transfer_token 
    (sender : address)
    (receiver : address)
    (token_address : address)
    (token_amount : nat) : operation = 
      let transfer_entrypoint : transfer_data contract = 
        match (Tezos.get_entrypoint_opt "%transfer" token_address : transfer_data contract option) with 
        | None -> failwith TreasuryErrors.invalid_token_address
        | Some transfer_entrypoint -> transfer_entrypoint
      in
      let transfer_data : transfer_data = 
      {
        from = sender;
        to_ = receiver;
        value = token_amount; 
      } in
      Tezos.transaction transfer_data 0tez transfer_entrypoint

  (* Transfer the XTZ to the appropriate address *)
  let transfer_xtz (receiver : address) (amount : tez) : operation =
    let received_contract : unit contract =
      match (Tezos.get_contract_opt receiver : unit contract option) with
      | None -> failwith TreasuryErrors.invalid_tezos_address
      | Some address -> address in
    Tezos.transaction () amount received_contract

  let handle_transfer (sender : address) (receiver : address) (received_token : token_amount) : operation =
    match received_token.token.address with 
    | None ->
      let xtz_amount = received_token.amount * 1tez in
      transfer_xtz receiver xtz_amount
    | Some token_address -> 
      transfer_token sender receiver token_address received_token.amount 

  (* Deposit tokens into storage *)
  let deposit_treasury (address : address) (received_token : token_amount) (treasury : treasury) : treasury =
    match Big_map.get_and_update
      address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      Big_map.add address received_token treasury
    | (Some old_token, treasury) ->
      let updated_amount = old_token.amount + received_token.amount in 
      Big_map.add address { old_token with amount = updated_amount } treasury
        
  let deposit 
    (deposit_address : address) 
    (treasury_vault : address)
    (deposited_token : token_amount) 
    (storage : storage) : storage =
      let treasury = deposit_treasury deposit_address deposited_token storage.treasury in
      let _ = handle_transfer deposit_address treasury_vault deposited_token in 
      { storage with treasury = treasury }

  (* Redeem the remaining tokens to the original storage after the end of swap process *)
  let redeem_treasury (redeem_address : address) (redeemed_token : token_amount) (treasury : treasury) : treasury =
    match Big_map.get_and_update
      redeem_address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      (failwith TreasuryErrors.incorrect_address : treasury)
    | (Some _, treasury) ->
        Big_map.add redeem_address redeemed_token treasury

  let redeem 
    (redeem_address : address) 
    (treasury_vault : address) 
    (redeemed_token : token_amount) 
    (storage : storage) : storage =
      let treasury = redeem_treasury redeem_address redeemed_token expiry storage.treasury in 
      let _ = handle_transfer treasury_vault redeem_address redeemed_token in
      { storage with treasury = treasury }
end
