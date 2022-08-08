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
  let transfer_token (sender : address) (receiver : address) (received_token : token_amount) : operation =
    let token_address = 
      match received_token.token.address with 
      | None -> failwith TreasuryErrors.not_found_token_address
      | Some address -> address in 
    let transfer_entrypoint = 
      match (Tezos.get_entrypoint_opt "%transfer" token_address : transfer_data contract option) with 
      | None -> failwith TreasuryErrors.invalid_token_address
      | Some transfer_entrypoint -> transfer_entrypoint
    in
    let transfer_data : transfer_data = 
    {
      from = sender;
      to_ = receiver;
      value = received_token.amount; 
    } in
    Tezos.transaction transfer_data 0tez transfer_entrypoint

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
    (immediate_address : address)
    (deposited_token : token_amount) 
    (storage : storage) : storage =
      let treasury = deposit_treasury deposit_address deposited_token storage.treasury in
      let _ = transfer_token deposit_address immediate_address deposited_token in 
      { storage with treasury = treasury }

  let handle_token_redemption 
    (old_token : token_amount) 
    (redeem_address : address) 
    (redeemed_token : token_amount)
    (expiry : boolean) 
    (treasury : treasury) : treasury = 
      if expiry || (redeemed_token.amount = old_token.amount) then 
        Big_map.remove redeem_address treasury 
      else 
        Big_map.add redeem_address redeemed_token treasury

  (* Redeem cancelled tokens from storage *)
  let redeem_treasury 
    (redeem_address : address) 
    (redeemed_token : token_amount) 
    (expiry : boolean) 
    (treasury : treasury) : treasury =
      match Big_map.get_and_update
        redeem_address
        (None : token_amount option)
        treasury
      with
      | (None, treasury) ->
        (failwith TreasuryErrors.incorrect_address : treasury)
      | (Some old_token, treasury) ->
        handle_token_redemption old_token redeem_address redeemed_token expiry treasury

  let redeem 
    (redeem_address : address) 
    (immediate_address : address) 
    (redeemed_token : token_amount) 
    (expiry : boolean) 
    (storage : storage) : storage =
      let _ = 
        if expiry && (redeemed_token.amount <> 0n) then 
          transfer_token immediate_address redeem_address redeemed_token 
      in 
      let treasury = redeem_treasury redeem_address redeemed_token expiry storage.treasury in 
      { storage with treasury = treasury }
end
