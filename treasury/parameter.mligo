module Types = struct
  type exchange_rate = {
    deposited_price : nat;
    received_price : nat;
  }

  type deposit = {
    deposited_amount : nat;
    exchange_rate : exchange_rate;
  }

  type redeem = {
    redeemed_amount : nat;
    exchange_rate : exchange_rate;
  }

  type t = 
  | Deposit of deposit
  | Redeem of redeem
end