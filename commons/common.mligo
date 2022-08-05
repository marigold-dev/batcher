
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
    created_at : timestamp;
  }


end

module Utils = struct

let list_rev (type a) (xs : a list) : a list =
  let rec rev (type a) ((xs, acc) : a list * a list) : a list =
    match xs with
    | [] -> acc
    | x :: xs -> rev (xs, (x :: acc)) in
  rev (xs, ([] : a list))

let concat (type a) (l : a list) (l2 : a list) : a list =
  let rec acc (type a) (l, l2, new_list : a list * a list * a list) : a list =
    match l,l2 with
      | [],[] -> list_rev new_list
      | [],h::tl -> acc (([] : a list),tl,(h :: new_list))
      | h::tl, next -> acc (tl,next,(h::new_list))
    in
  acc (l, l2, ([] : a list))

end