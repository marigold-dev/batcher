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

let assert_or_fail
    (predicate: bool)
    (error: nat) = 
    if not predicate then failwith error else ()

let find_or_fail
     (type a b)
     (key: a)
     (error: nat)
     (bmap:  (a,b) big_map) : b =
     match Big_map.find_opt key bmap with
     | None -> failwith error
     | Some v -> v

let bi_map_opt_sn
    (type a b)
    (f_some: a -> b)
    (f_none: unit -> b)
    (boxed: a option): b = 
    match boxed with
    | Some v -> f_some v
    | None -> f_none ()

let map_opt
   (type a b)
   (f: a -> b)
   (boxed: a option): b option = 
   match boxed with
   | None -> None
   | Some v -> Some (f v)

let bind_opt
  (type a b)
  (f: a -> b option)
  (boxed: a option): b option = 
  match boxed with
  | None -> None
  | Some v -> f v

