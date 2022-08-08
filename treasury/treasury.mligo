#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "errors.mligo" "TreasuryErrors"

module Utils = struct
  type exchange_rate = CommonTypes.Types.exchange_rate
  type storage = CommonStorage.Types.t
  type token_amount = CommonTypes.Types.token_amount

  (* Get the number of swapped tokens based on the current exchange_rate *)
  let get_swapped_value (token : token_amount) (exchange_rate : exchange_rate) : token_amount  =
    let { quote; base } = exchange_rate in
    let quote_value = quote.value in
    let base_value = base.value in
    let updated_amount = (token.amount * quote_value) / base_value in
    { token =  quote.token; amount = updated_amount;  }

  (* A person deposits an amount of tokens into storage for swapping *)
  let deposit_treasury (deposit_address : address) (deposited_token : token_amount) (treasury : CommonStorage.Types.treasury) =
    match Big_map.get_and_update
      deposit_address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      Big_map.add deposit_address deposited_token treasury
    | (Some old_token, treasury) ->
      let updated_amount = old_token.amount + deposited_token.amount in
      Big_map.add deposit_address { old_token with amount = updated_amount } treasury

  (* This swapped tokens are owned by the given person *)
  let deposit_swapped_token
    (deposit_address : address)
    (deposited_token : token_amount)
    (exchange_rate : exchange_rate)
    (swapped_treasury : CommonStorage.Types.swapped_treasury) =
      let swapped_token = get_swapped_value deposited_token exchange_rate in
      match Big_map.get_and_update
        deposit_address
        (None : token_amount option)
        swapped_treasury
      with
      | (None, swapped_treasury) ->
        Big_map.add deposit_address swapped_token swapped_treasury
      | (Some old_token, swapped_treasury) ->
        let updated_amount = old_token.amount + swapped_token.amount in
        Big_map.add deposit_address { old_token with amount = updated_amount } swapped_treasury

  let deposit (deposit_address : address) (deposited_value : CommonTypes.Types.deposit) (storage : CommonStorage.Types.t) =
    let { deposited_token_amount; exchange_rate } = deposited_value in
    let treasury = storage.treasury in
    let swapped_treasury = storage.swapped_treasury in
    let treasury = deposit_treasury deposit_address deposited_token_amount treasury in
    let swapped_treasury = deposit_swapped_token deposit_address deposited_token_amount exchange_rate swapped_treasury in
    { storage with  treasury = treasury; swapped_treasury = swapped_treasury }

  (* A person redeems an amount of tokens from storage *)
  let redeem_treasury (redeem_address : address) (redeemed_token : token_amount) (treasury : CommonStorage.Types.treasury) =
    match Big_map.get_and_update
      redeem_address
      (None : token_amount option)
      treasury
    with
    | (None, treasury) ->
      (failwith TreasuryErrors.incorrect_address : CommonStorage.Types.treasury)
    | (Some old_token, treasury) ->
      if redeemed_token.amount > old_token.amount then
        (failwith TreasuryErrors.greater_than_owned_token : CommonStorage.Types.treasury)
      else
        let updated_amount = abs (old_token.amount - redeemed_token.amount) in
        Big_map.add redeem_address { old_token with amount = updated_amount } treasury

  (* This swapped tokens are redeemed from the given person *)
  let redeem_swapped_token
    (redeem_address : address)
    (redeemed_token : token_amount)
    (exchange_rate : exchange_rate)
    (swapped_treasury : CommonStorage.Types.swapped_treasury) =
      let swapped_token = get_swapped_value redeemed_token exchange_rate in
      match Big_map.get_and_update
        redeem_address
        (None : token_amount option)
        swapped_treasury
      with
      | (None, swapped_treasury) ->
        (failwith TreasuryErrors.incorrect_address : CommonStorage.Types.swapped_treasury)
      | (Some old_token, swapped_treasury) ->
        if swapped_token.amount > old_token.amount then
          (failwith TreasuryErrors.greater_than_owned_token : CommonStorage.Types.swapped_treasury)
        else
          let updated_amount = abs (old_token.amount - swapped_token.amount) in
          Big_map.add redeem_address { old_token with amount = updated_amount } swapped_treasury

  let redeem (redeem_address : address) (redeemed_value : CommonTypes.Types.redeem) (storage : CommonStorage.Types.t) =
    let { redeemed_token_amount; exchange_rate } = redeemed_value in
    let treasury = storage.treasury in
    let swapped_treasury  = storage.swapped_treasury in
    let treasury = redeem_treasury redeem_address redeemed_token_amount treasury in
    let swapped_treasury = redeem_swapped_token redeem_address redeemed_token_amount exchange_rate swapped_treasury in
    { storage with treasury = treasury; swapped_treasury = swapped_treasury }
end
