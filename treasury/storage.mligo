#import "errors.mligo" "Errors" 
#import "Parameter.mligo" "Parameter"
#import "../commons/common.mligo" "Common"

type token_value = Common.Types.token_value

module Types = struct
  (* The deposited tokens *)
  type treasury = (address, token_value) big_map

  (* The swapped tokens *)
  type swapped_treasury = (address, token_value) big_map

  type t = {
    treasury : treasury;
    swapped_treasury : swapped_treasury;
  }
end 

module Utils = struct
  type deposit = Parameter.Types.deposit 
  type redeem = Parameter.Types.redeem  
  type exchange_rate = Common.Types.exchange_rate

  (* Get the number of swapped tokens based on the current exchange_rate *)
  let get_swapped_value (token : token_value) (exchange_rate : exchange_rate) = 
     let { quote; base } = exchange_rate in 
    let quote_value = quote.token.value in 
    let base_value = base.token.value in 
    let value = (token.value * quote_value) / base_value in 
    { quote.token with value = value }

  (* A person deposits an amount of tokens into storage for swapping *)
  let deposit_treasury (deposit_address : address) (deposited_token : token_value) (treasury : Types.treasury) = 
    match Big_map.get_and_update 
      deposit_address
      (None : token_value option) 
      treasury
    with 
    | (None, treasury) -> 
      Big_map.add deposit_address deposited_token treasury
    | (Some old_token, treasury) ->  
      let value = old_token.value + deposited_token.value in 
      Big_map.add deposit_address { old_token with value = value } treasury
  
  (* This swapped tokens are owned by the given person *)
  let deposit_swapped_token 
    (deposit_address : address) 
    (deposited_token : token_value) 
    (exchange_rate : exchange_rate) 
    (swapped_treasury : Types.swapped_treasury) = 
      let swapped_token = get_swapped_value deposited_token exchange_rate in  
      match Big_map.get_and_update 
        deposit_address
        (None : token_value option) 
        swapped_treasury
      with 
      | (None, swapped_treasury) -> 
        Big_map.add deposit_address swapped_token swapped_treasury
      | (Some old_token, swapped_treasury) -> 
        let value = old_token.value + swapped_token.value in 
        Big_map.add deposit_address { old_token with value = value } swapped_treasury

  let deposit (deposit_address : address) (deposited_value : deposit) (storage : Types.t) = 
    let { deposited_token; exchange_rate } = deposited_value in
    let { treasury; swapped_treasury } = storage in  
    let treasury = deposit_treasury deposit_address deposited_token treasury in   
    let swapped_treasury = deposit_swapped_token deposit_address deposited_token exchange_rate swapped_treasury in 
    { treasury = treasury; swapped_treasury = swapped_treasury }

  (* A person redeems an amount of tokens from storage *)
  let redeem_treasury (redeem_address : address) (redeemed_token : token_value) (treasury : Types.treasury) = 
    match Big_map.get_and_update 
      redeem_address
      (None : token_value option) 
      treasury
    with 
    | (None, treasury) -> 
      (failwith Errors.incorrect_address : Types.treasury) 
    | (Some old_token, treasury) -> 
      if redeemed_token.value > old_token.value then 
        (failwith Errors.greater_than_owned_token : Types.treasury) 
      else 
        let value = abs (old_token.value - redeemed_token.value) in 
        Big_map.add redeem_address { old_token with value = value } treasury
  
  (* This swapped tokens are redeemed from the given person *)
  let redeem_swapped_token 
    (redeem_address : address) 
    (redeemed_token : token_value) 
    (exchange_rate : exchange_rate) 
    (swapped_treasury : Types.swapped_treasury) = 
      let swapped_token = get_swapped_value redeemed_token exchange_rate in 
      match Big_map.get_and_update 
        redeem_address
        (None : token_value option) 
        swapped_treasury
      with 
      | (None, swapped_treasury) -> 
        (failwith Errors.incorrect_address : Types.swapped_treasury) 
      | (Some old_token, swapped_treasury) -> 
        if swapped_token.value > old_token.value then 
          (failwith Errors.greater_than_owned_token : Types.swapped_treasury) 
        else
          let value = abs (old_token.value - swapped_token.value) in 
          Big_map.add redeem_address { old_token with value = value } swapped_treasury

  let redeem (redeem_address : address) (redeemed_value : redeem) (storage : Types.t) = 
    let { redeemed_token; exchange_rate } = redeemed_value in
    let { treasury; swapped_treasury } = storage in  
    let treasury = redeem_treasury redeem_address redeemed_token treasury in   
    let swapped_treasury = redeem_swapped_token redeem_address redeemed_token exchange_rate swapped_treasury in 
    { treasury = treasury; swapped_treasury = swapped_treasury }
end 