#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "errors.mligo" "TreasuryErrors"

module Utils = struct
  type storage = CommonStorage.Types.t
  type treasury = CommonStorage.Types.treasury
  type token_amount = CommonTypes.Types.token_amount

  (* Deposit base or swapped tokens into storage *)
  let handle_treasury (address : address) (received_token : token_amount) (treasury : treasury) : treasury =
    match Big_map.get_and_update
      address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      Big_map.add address received_token treasury
    | (Some old_token, treasury) ->
      if old_token.token = received_token.token then
        let updated_amount = old_token.amount + received_token.amount in 
        Big_map.add address { old_token with amount = updated_amount } treasury
      else 
        Big_map.add address received_token treasury

  let deposit (deposit_address : address) (deposited_token : token_amount) (storage : storage) : storage =
    let treasury = handle_treasury deposit_address deposited_token storage.treasury in 
    { storage with treasury = treasury }

  let match_order (address : address) (swapped_token : token_amount) (storage : storage) : storage = 
    let treasury = handle_treasury address swapped_token storage.treasury in 
    { storage with treasury = treasury }

  (* Redeem cancelled tokens from storage *)
  let redeem_treasury (redeem_address : address) (treasury : treasury) : treasury =
    match Big_map.get_and_update
      redeem_address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      (failwith TreasuryErrors.incorrect_address : treasury)
    | (Some _, treasury) ->
      Big_map.remove redeem_address treasury

  let redeem (redeem_address : address) (storage : storage) : storage =
    let treasury = redeem_treasury redeem_address storage.treasury in 
    { storage with treasury = treasury }
end
