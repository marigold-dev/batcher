type mint_burn_request = { 
   name: string;
   amount: nat;
}

type token = [@layout:comb] {
  token_id: nat;
  name : string;
  address : address option;
  decimals : nat;
  standard : string option;
}

type market_token = {
   circulation: nat;
   token: token;

}
