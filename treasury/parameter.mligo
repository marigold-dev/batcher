#import "../commons/common.mligo" "Common"

module Types = struct
  type exchange_rate = Common.Types.exchange_rate 
  type token_value = Common.Types.token_value

  type deposit = {
    deposited_token : token_value;
    exchange_rate : exchange_rate;
  }

  type redeem = {
    redeemed_token : token_value;
    exchange_rate : exchange_rate;
  }

  type t = 
  | Deposit of deposit
  | Redeem of redeem
end