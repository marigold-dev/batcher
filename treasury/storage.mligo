#import "errors.mligo" "Errors" 
#import "Parameter.mligo" "Parameter"

module Types = struct
  (* The deposited tokens *)
  type treasury = (address, nat) big_map

  (* The swapped tokens *)
  type swapped_token = (address, nat) big_map

  type t = {
    treasury : treasury;
    swapped_token : swapped_token;
  }
end 

module Utils = struct
  type deposit = Parameter.Types.deposit 
  type redeem = Parameter.Types.redeem  
  type exchange_rate = Parameter.Types.exchange_rate

  (* A person deposits an amount of tokens into storage for swapping *)
  let deposit_treasury (deposit_address : address) (deposited_amount : nat) (treasury : Types.treasury) = 
    match Big_map.get_and_update 
      deposit_address
      (None : nat option) 
      treasury
    with 
    | (None, treasury) -> 
      Big_map.add deposit_address deposited_amount treasury
    | (Some old_amount, treasury) -> 
      let updated_amount = old_amount + deposited_amount in 
      Big_map.add deposit_address updated_amount treasury
  
  (* This swapped tokens are owned by the given person *)
  let deposit_swapped_token (deposit_address : address) (deposited_amount : nat) (exchange_rate : exchange_rate) (swapped_token : Types.swapped_token) = 
    let { deposited_price; received_price } = exchange_rate in 
    let swapped_amount = (deposited_amount * received_price) / deposited_price in  
    match Big_map.get_and_update 
      deposit_address
      (None : nat option) 
      swapped_token
    with 
    | (None, swapped_token) -> 
      Big_map.add deposit_address swapped_amount swapped_token
    | (Some old_amount, swapped_token) -> 
      let updated_amount = old_amount + swapped_amount in 
      Big_map.add deposit_address updated_amount swapped_token

  let deposit (deposit_address : address) (deposited_value : deposit) (storage : Types.t) = 
    let { deposited_amount; exchange_rate } = deposited_value in
    let { treasury; swapped_token } = storage in  
    let treasury = deposit_treasury deposit_address deposited_amount treasury in   
    let swapped_token = deposit_swapped_token deposit_address deposited_amount exchange_rate swapped_token in 
    { treasury = treasury; swapped_token = swapped_token }

  (* A person redeems an amount of tokens from storage *)
  let redeem_treasury (redeem_address : address) (redeemed_amount : nat) (treasury : Types.treasury) = 
    match Big_map.get_and_update 
      redeem_address
      (None : nat option) 
      treasury
    with 
    | (None, treasury) -> 
      (failwith Errors.not_found_address : Types.treasury) 
    | (Some old_amount, treasury) -> 
      if redeemed_amount > old_amount then 
        (failwith Errors.greater_than_owned_token : Types.treasury) 
      else 
        let updated_amount = abs (old_amount - redeemed_amount) in 
        Big_map.add redeem_address updated_amount treasury
  
  (* This swapped tokens are redeemed from the given person *)
  let redeem_swapped_token (redeem_address : address) (redeemed_amount : nat) (exchange_rate : exchange_rate) (swapped_token : Types.swapped_token) = 
    let { deposited_price; received_price } = exchange_rate in 
    let swapped_amount = (redeemed_amount * received_price) / deposited_price in  
    match Big_map.get_and_update 
      redeem_address
      (None : nat option) 
      swapped_token
    with 
    | (None, swapped_token) -> 
      (failwith Errors.not_found_address : Types.swapped_token) 
    | (Some old_amount, swapped_token) -> 
      if swapped_amount > old_amount then 
        (failwith Errors.greater_than_owned_token : Types.swapped_token) 
      else
        let updated_amount = abs (old_amount - swapped_amount) in 
        Big_map.add redeem_address updated_amount swapped_token

  let redeem (redeem_address : address) (redeemed_value : redeem) (storage : Types.t) = 
    let { redeemed_amount; exchange_rate } = redeemed_value in
    let { treasury; swapped_token } = storage in  
    let treasury = redeem_treasury redeem_address redeemed_amount treasury in   
    let swapped_token = redeem_swapped_token redeem_address redeemed_amount exchange_rate swapped_token in 
    { treasury = treasury; swapped_token = swapped_token }
end 