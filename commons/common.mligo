
module Types = struct

  (* Associate alias to token address *)
  type token = {
    [@layout:comb]
    name : string;
    address : address;
  }

  (* A token value ascribes a value to token metadata *)
  type token_value = {
     [@layout:comb]
     token : token;
     value : nat;
  }

  (* Price associates a timestamp to a token value to fix in time *)
  type price = {
     [@layout:comb]
     token : token_value;
     when : timestamp;
  }

  type exchange_rate = {
     [@layout:comb]
     quote : price;
     base : price;
  }

  type swap = {
   from : token;
   to : token;
  }

  type swap_order = {
    trader : address;
    swap  : swap;
    to_price : nat;
    tolerance : nat;
    deadline : timestamp;
  }


end


type result = (operation list) * storage

}
