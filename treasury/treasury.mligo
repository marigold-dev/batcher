#import "../commons/types.mligo" "CommonTypes"
#import "../commons/storage.mligo" "CommonStorage"
#import "errors.mligo" "TreasuryErrors"

module Utils = struct
  type exchange_rate = CommonTypes.Types.exchange_rate
  type storage = CommonStorage.Types.t
  type token_amount = CommonTypes.Types.token_amount
  type treasury_value = CommonStorage.Types.treasury_value

  (* Get the number of swapped tokens based on the current exchange xsrate *)
  let get_swapped_token (token : token_amount) (exchange_rate : exchange_rate) : token_amount  =
    let { quote; base } = exchange_rate in
    let quote_value = quote.value in
    let base_value = base.value in
    let updated_amount = (token.amount * quote_value) / base_value in
    { token = quote.token; amount = updated_amount }

  let get_deposited_base_token (base_token : token_amount) (deposited_token : token_amount) = 
    let base_token_amount = base_token.amount + deposited_token.amount in
    { base_token with amount = base_token_amount }

  let get_deposited_swap_token (swapped_token : token_amount) (deposited_token : token_amount) (exchange_rate : exchange_rate) =
    let deposited_swap_token = get_swapped_token deposited_token exchange_rate in 
    let swapped_token_amount = swapped_token.amount + deposited_swap_token.amount in 
    { swapped_token with amount = swapped_token_amount }

  (* A person deposits an amount of tokens into storage and get the corresponding swapped tokens *)
  let deposit_treasury 
    (deposit_address : address) 
    (deposited_token : token_amount) 
    (exchange_rate : exchange_rate) 
    (treasury : CommonStorage.Types.treasury) =
      match Big_map.get_and_update
        deposit_address
        (None : treasury_value option)
        treasury
      with
      | (None, treasury) ->
        let swapped_token = get_swapped_token deposited_token exchange_rate in  
        Big_map.add deposit_address { base_token = deposited_token; swapped_token = swapped_token } treasury
      | (Some old_value, treasury) ->
        let base_token = get_deposited_base_token old_value.base_token deposited_token in 
        let swapped_token = get_deposited_swap_token old_value.swapped_token deposited_token exchange_rate in 
        Big_map.add deposit_address { base_token = base_token; swapped_token = swapped_token } treasury

  let deposit (deposit_address : address) (deposited_value : CommonTypes.Types.deposit) (storage : CommonStorage.Types.t) =
    let { deposited_token; exchange_rate } = deposited_value in
    let treasury = deposit_treasury deposit_address deposited_token exchange_rate storage in
    { storage with treasury = treasury }

  let get_redeemed_base_token (base_token : token_amount) (redeemed_token : token_amount) = 
    if redeemed_token.amount > base_token.amount then 
      (failwith TreasuryErrors.greater_than_original_token : token_amount)
    else 
      let base_token_amount = abs (base_token.amount - redeemed_token.amount) in 
      { base_token with amount = base_token_amount }

  let get_redeemed_swap_token (swapped_token : token_amount) (redeemed_token : token_amount) (exchange_rate : exchange_rate) = 
    let redeemed_swap_token = get_swapped_token redeemed_token exchange_rate in 
    if redeemed_swap_token.amount > swapped_token.amount then 
      (failwith TreasuryErrors.greater_than_swapped_token : token_amount)
    else 
      let swapped_token_amount = abs (swapped_token.amount - redeemed_swap_token.amount) in 
      { swapped_token with amount = swapped_token_amount }

  (* A person redeems an amount of tokens from storage, i.e it is the result of partial swap *)
  let redeem_treasury 
    (redeem_address : address) 
    (redeemed_token : token_amount)
    (exchange_rate : exchange_rate) 
    (treasury : CommonStorage.Types.treasury) =
    match Big_map.get_and_update
      redeem_address
      (None : treasury_value option)
      treasury
    with
    | (None, treasury) ->
      (failwith TreasuryErrors.incorrect_address : CommonStorage.Types.treasury)
    | (Some old_value, treasury) ->
      let base_token = get_redeemed_base_token old_value.base_token redeemed_token in 
      let swapped_token = get_redeemed_swap_token old_value.swapped_token redeemed_token exchange_rate in
      Big_map.add redeem_address { base_token = base_token; swapped_token = swapped_token } treasury

  let redeem (redeem_address : address) (redeemed_value : CommonTypes.Types.redeem) (storage : CommonStorage.Types.t) =
    let { redeemed_token; exchange_rate } = redeemed_value in
    let treasury = redeem_treasury redeem_address redeemed_token exchange_rate storage in
    { storage with treasury = treasury }
end
